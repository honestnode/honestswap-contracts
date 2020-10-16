import {deployments, ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, utils} from 'ethers';
import {getNamedAccounts, NamedAccounts} from '../scripts/HonestContract.test';

describe('HonestFee', () => {
  let namedAccounts: NamedAccounts;
  let proxyAdmin: Contract, honestAsset: Contract, fee: Contract;

  const initializeAccounts = async () => {
    namedAccounts = await getNamedAccounts();
  };

  const deployContracts = async () => {
    await deployments.fixture();
    proxyAdmin = await ethers.getContract('DelayedProxyAdmin', namedAccounts.supervisor.signer);
    honestAsset = await ethers.getContract('HonestAsset', namedAccounts.dealer.signer);
    fee = await ethers.getContract('HonestFee', namedAccounts.dealer.signer);
  };

  const mintHonestAsset = async (account: string, amount: string) => {
    const assetManagerRole = await honestAsset.ASSET_MANAGER();
    await proxyAdmin.grantProxyRole(honestAsset.address, assetManagerRole, namedAccounts.dealer.address);

    await honestAsset.mint(account, utils.parseUnits(amount, 18));

    await proxyAdmin.revokeProxyRole(honestAsset.address, assetManagerRole, namedAccounts.dealer.address);
  };

  const assertBalances = async (expectTotalFee: string, expectClaimableRewards: string, expectReservedRewards: string) => {
    const totalFee = await fee.totalFee();
    expect(totalFee).to.equal(utils.parseUnits(expectTotalFee, 18));
    const claimableRewards = await fee.claimableRewards();
    expect(claimableRewards).to.equal(utils.parseUnits(expectClaimableRewards, 18));
    const reservedRewards = await fee.reservedRewards();
    expect(reservedRewards).to.equal(utils.parseUnits(expectReservedRewards, 18));
  };

  before(async function () {
    await initializeAccounts();
    await deployContracts();
  });

  it('save rewards', async () => {
    await mintHonestAsset(fee.address, '100');

    await assertBalances('100', '80', '20');
  });

  it('distribute HonestAsset rewards without authorization', async () => {
    await expect(fee.distributeHonestAssetRewards(namedAccounts.dummy1.address, utils.parseUnits('1', 18))).to.reverted;
  });

  it('distribute HonestAsset rewards', async () => {
    const vaultRole = await fee.VAULT();
    await proxyAdmin.grantProxyRole(fee.address, vaultRole, namedAccounts.dealer.address);

    await fee.distributeHonestAssetRewards(namedAccounts.dummy1.address, utils.parseUnits('1', 18));

    const balance = await honestAsset.balanceOf(namedAccounts.dummy1.address);
    expect(balance).to.equal(utils.parseUnits('80', 18));

    await assertBalances('20', '0', '20');

    await proxyAdmin.revokeProxyRole(fee.address, vaultRole, namedAccounts.dealer.address);
  });

  it('distribute reserved rewards', async () => {
    await mintHonestAsset(fee.address, '100');
    const governorRole = await fee.GOVERNOR();
    await proxyAdmin.grantProxyRole(fee.address, governorRole, namedAccounts.dealer.address);

    await fee.distributeReservedRewards(namedAccounts.dummy2.address);

    const balance = await honestAsset.balanceOf(namedAccounts.dummy2.address);
    expect(balance).to.equal(utils.parseUnits('40', 18));

    await assertBalances('80', '80', '0');

    await proxyAdmin.revokeProxyRole(fee.address, governorRole, namedAccounts.dealer.address);
  });
});
