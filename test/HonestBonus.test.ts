import {deployments, ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, utils} from 'ethers';
import {getUpgradableContract} from '../scripts/HonestContract.deploy';
import {getNamedAccounts, NamedAccounts} from '../scripts/HonestContract.test';

describe('HonestBonus', () => {

  let namedAccounts: NamedAccounts;
  let honestBonus: Contract, honestVault: Contract, role: string;
  let dai: Contract, tusd: Contract, usdc: Contract, usdt: Contract;

  const initializeAccounts = async () => {
    namedAccounts = await getNamedAccounts();
  };

  const deployContracts = async () => {
    await deployments.fixture();
    honestBonus = await getUpgradableContract('HonestBonus', namedAccounts.dummy1.signer);
    honestVault = await getUpgradableContract('HonestVault', namedAccounts.supervisor.signer);
    dai = await ethers.getContract('MockDAI', namedAccounts.supervisor.signer);
    tusd = await ethers.getContract('MockTUSD', namedAccounts.supervisor.signer);
    usdc = await ethers.getContract('MockUSDC', namedAccounts.supervisor.signer);
    usdt = await ethers.getContract('MockUSDT', namedAccounts.supervisor.signer);
  };

  before(async () => {
    await initializeAccounts();
    await deployContracts();
    role = await honestBonus.assetManagerRole();
  });

  it('without authorized, revert', async () => {
    await expect(honestBonus.hasBonus(dai.address)).to.reverted;
    await expect(honestBonus.calculateMintBonus([dai.address], [utils.parseUnits('100', 18)])).to.reverted;
    await namedAccounts.supervisor.connect(honestBonus).grantRole(role, namedAccounts.dummy1.address);
  });

  it('has bonus', async () => {
    const result = await honestBonus.hasBonus(dai.address);
    expect(result).to.equal(true);
  });

  it('calculate bonus', async () => {
    const result = await honestBonus.calculateMintBonus(
      [dai.address, tusd.address, usdc.address, usdt.address],
      [utils.parseUnits('100', 18), utils.parseUnits('100', 18), utils.parseUnits('100', 18), utils.parseUnits('100', 18)]);

    expect(result).to.equal(utils.parseUnits('400', 18));
  });

  it('has bonus', async () => {
    await dai.mint(honestVault.address, utils.parseUnits('100', 18));
    await tusd.mint(honestVault.address, utils.parseUnits('200', 18));
    await usdc.mint(honestVault.address, utils.parseUnits('200', 6));
    let result = await honestBonus.hasBonus(dai.address);
    expect(result).to.equal(true);
    result = await honestBonus.hasBonus(tusd.address);
    expect(result).to.equal(false);
    result = await honestBonus.hasBonus(usdc.address);
    expect(result).to.equal(false);
    result = await honestBonus.hasBonus(usdt.address);
    expect(result).to.equal(true);
  });

  it('calculate bonus', async () => {
    const result = await honestBonus.calculateMintBonus(
      [dai.address, tusd.address, usdc.address, usdt.address],
      [utils.parseUnits('100', 18), utils.parseUnits('100', 18), utils.parseUnits('100', 18), utils.parseUnits('100', 18)]);

    expect(result).to.equal(utils.parseUnits('120', 18));
  });
});
