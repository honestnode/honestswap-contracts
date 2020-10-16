import {deployments, ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, utils} from 'ethers';
import {getUpgradableContract} from '../scripts/HonestContract.deploy';
import {expectAmount, getNamedAccounts, NamedAccounts} from '../scripts/HonestContract.test';

describe('HonestAssetManager', () => {

  let namedAccounts: NamedAccounts;
  let honestConfiguration: Contract, honestAsset: Contract, honestVault: Contract,
    honestAssetManager: Contract;
  let dai: Contract, tusd: Contract, usdc: Contract, usdt: Contract;

  const initializeAccounts = async () => {
    namedAccounts = await getNamedAccounts();
  };

  const deployContracts = async () => {
    await deployments.fixture();

    honestAsset = await getUpgradableContract('HonestAsset', namedAccounts.dummy1.signer);
    honestConfiguration = await getUpgradableContract('HonestConfiguration', namedAccounts.dealer.signer);
    honestVault = await getUpgradableContract('HonestVault', namedAccounts.dealer.signer);
    honestAssetManager = await getUpgradableContract('HonestAssetManager', namedAccounts.dummy1.signer);
    dai = await ethers.getContract('MockDAI', namedAccounts.dummy1.signer);
    tusd = await ethers.getContract('MockTUSD', namedAccounts.dummy1.signer);
    usdc = await ethers.getContract('MockUSDC', namedAccounts.dummy1.signer);
    usdt = await ethers.getContract('MockUSDT', namedAccounts.dummy1.signer);
  };

  const mintTokens = async (account: string) => {
    await namedAccounts.supervisor.connect(dai).mint(account, utils.parseUnits('100', 18));
    await namedAccounts.supervisor.connect(tusd).mint(account, utils.parseUnits('100', 18));
    await namedAccounts.supervisor.connect(usdc).mint(account, utils.parseUnits('100', 6));
    await namedAccounts.supervisor.connect(usdt).mint(account, utils.parseUnits('100', 6));
  };

  const assertAssetBalances = async (account: string, balances: string[]) => {
    let balance = await dai.balanceOf(account);
    expectAmount(balance, balances[0], 18);
    balance = await tusd.balanceOf(account);
    expectAmount(balance, balances[1], 18);
    balance = await usdc.balanceOf(account);
    expectAmount(balance, balances[2], 6);
    balance = await usdt.balanceOf(account);
    expectAmount(balance, balances[3], 6);
  };

  before(async () => {
    await initializeAccounts();
    await deployContracts();
    await mintTokens(namedAccounts.dummy1.address);
    await mintTokens(namedAccounts.dummy2.address);
  });

  it('mint', async () => {
    await dai.approve(honestAssetManager.address, utils.parseUnits('20', 18));
    await tusd.approve(honestAssetManager.address, utils.parseUnits('20', 18));
    await usdc.approve(honestAssetManager.address, utils.parseUnits('20', 6));
    await usdt.approve(honestAssetManager.address, utils.parseUnits('20', 6));

    await honestAssetManager.mint(
      [dai.address, tusd.address, usdc.address, usdt.address],
      [utils.parseUnits('20', 18), utils.parseUnits('20', 18),
        utils.parseUnits('20', 6), utils.parseUnits('20', 6)]);

    const amount = await honestAsset.balanceOf(namedAccounts.dummy1.address);

    expect(amount).to.equal(utils.parseUnits('80', 18));
    await assertAssetBalances(honestVault.address, ['20', '20', '20', '20']);
  });

  it('deposit', async () => {
    await honestAsset.approve(honestAssetManager.address, utils.parseUnits('40', 18));

    await honestAssetManager.deposit(utils.parseUnits('40', 18));

    const amount = await honestAsset.balanceOf(namedAccounts.dummy1.address);
    expect(amount).to.equal(utils.parseUnits('40', 18));
    await assertAssetBalances(honestVault.address, ['10', '10', '10', '10']);
  });

  it('swap', async () => {
    await usdt.approve(honestAssetManager.address, utils.parseUnits('10.1', 6));

    await honestAssetManager.swap(usdt.address, dai.address, utils.parseUnits('10', 6));

    let amount = await dai.balanceOf(namedAccounts.dummy1.address);
    expect(amount).to.equal(utils.parseUnits('90', 18));
    amount = await usdt.balanceOf(namedAccounts.dummy1.address);
    expect(amount).to.equal(utils.parseUnits('69.9', 6));

    await assertAssetBalances(honestVault.address, ['0', '10', '10', '20.1']);
  });

  it('withdraw', async () => {
    await honestAssetManager.withdraw(utils.parseUnits('40', 18));

    const amount = await honestAsset.balanceOf(namedAccounts.dummy1.address);
    expect(amount).to.gte(utils.parseUnits('80', 18));

    await assertAssetBalances(honestVault.address, ['>0', '>0', '>0', '>0']);
  });

  it('redeem proportionally', async () => {

    const amount = await honestAsset.balanceOf(namedAccounts.dummy1.address);
    await honestAsset.approve(honestAssetManager.address, amount);
    await honestAssetManager.redeemProportionally(amount);

    await assertAssetBalances(namedAccounts.dummy1.address, ['>99', '>99', '>99', '>99']);
    await assertAssetBalances(honestVault.address, ['>0', '>0', '>0', '>0']);
  });
});