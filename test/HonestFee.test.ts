import {deployments, ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, utils} from 'ethers';
import {getUpgradableContract} from '../scripts/HonestContract.deploy';
import {getNamedAccounts, NamedAccounts} from '../scripts/HonestContract.test';

describe('HonestFee', () => {
  let namedAccounts: NamedAccounts;
  let honestAsset: Contract, fee: Contract;

  const initializeAccounts = async () => {
    namedAccounts = await getNamedAccounts();
  };

  const deployContracts = async () => {
    await deployments.fixture();
    honestAsset = await getUpgradableContract('HonestAsset', namedAccounts.dealer.signer);
    fee = await getUpgradableContract('HonestFee', namedAccounts.dealer.signer);
  };

  const mintHonestAsset = async (account: string, amount: string) => {
    const assetManagerRole = await honestAsset.assetManagerRole();
    namedAccounts.supervisor.connect(honestAsset).grantRole(assetManagerRole, namedAccounts.dealer.address);

    await honestAsset.mint(account, utils.parseUnits(amount, 18));

    namedAccounts.supervisor.connect(honestAsset).revokeRole(assetManagerRole, namedAccounts.dealer.address);
  };

  const assertBalances = async (expectTotalFee: string, expectClaimableRewards: string, expectReservedRewards: string) => {
    const totalFee = await fee.totalFee();
    expect(totalFee).to.equal(utils.parseUnits(expectTotalFee, 18));
    const claimableRewards = await fee.claimableRewards();
    expect(claimableRewards).to.equal(utils.parseUnits(expectClaimableRewards, 18));
    const reservedRewards = await fee.reservedRewards();
    expect(reservedRewards).to.equal(utils.parseUnits(expectReservedRewards, 18));
  };

  before(async () => {
    await initializeAccounts();
    await deployContracts();
  });

  it('save rewards', async () => {
    await mintHonestAsset(fee.address, '100');

    await assertBalances('100', '80', '20');
  });

  it('distribute claimable rewards without authorization', async () => {
    await expect(fee.distributeClaimableRewards(namedAccounts.dummy1.address, utils.parseUnits('1', 18))).to.reverted;
  });

  it('distribute claimable rewards', async () => {
    const vaultRole = await fee.vaultRole();
    namedAccounts.supervisor.connect(fee).grantRole(vaultRole, namedAccounts.dealer.address);

    await fee.distributeClaimableRewards(namedAccounts.dummy1.address, utils.parseUnits('1', 18));

    const balance = await honestAsset.balanceOf(namedAccounts.dummy1.address);
    expect(balance).to.equal(utils.parseUnits('80', 18));

    await assertBalances('20', '0', '20');

    namedAccounts.supervisor.connect(fee).revokeRole(vaultRole, namedAccounts.dealer.address);
  });

  it('distribute reserved rewards', async () => {
    await mintHonestAsset(fee.address, '100');
    const governorRole = await fee.DEFAULT_ADMIN_ROLE();
    namedAccounts.supervisor.connect(fee).grantRole(governorRole, namedAccounts.dealer.address);

    await fee.distributeReservedRewards(namedAccounts.dummy2.address);

    const balance = await honestAsset.balanceOf(namedAccounts.dummy2.address);
    expect(balance).to.equal(utils.parseUnits('40', 18));

    await assertBalances('80', '80', '0');

    namedAccounts.supervisor.connect(fee).revokeRole(governorRole, namedAccounts.dealer.address);
  });
});
