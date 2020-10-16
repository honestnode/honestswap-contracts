import {deployments, ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, utils} from 'ethers';
import {getNamedAccounts, NamedAccounts} from '../scripts/HonestContract.test';

describe('HonestAsset', () => {

  let namedAccounts: NamedAccounts;
  let honestAsset: Contract, proxyAdmin: Contract, role: string;

  const initializeAccounts = async () => {
    namedAccounts = await getNamedAccounts();
  };

  const deployContracts = async () => {
    await deployments.fixture();
    proxyAdmin = await ethers.getContract('DelayedProxyAdmin', namedAccounts.supervisor.signer);
    honestAsset = await ethers.getContract('HonestAsset', namedAccounts.dummy1.signer);
  };

  before(async () => {
    await initializeAccounts();
    await deployContracts();
    role = await honestAsset.ASSET_MANAGER();
  });

  it('mint without authorized, revert', async () => {
    await expect(honestAsset.mint(namedAccounts.dummy1.address, utils.parseUnits('100', 18))).to.reverted;
  });

  it('mint 100 to dummy', async () => {
    await proxyAdmin.grantProxyRole(honestAsset.address, role, namedAccounts.dummy1.address);

    const result = await honestAsset.callStatic.mint(namedAccounts.dummy1.address, utils.parseUnits('100', 18));
    expect(result).to.equal(true);
    await honestAsset.mint(namedAccounts.dummy1.address, utils.parseUnits('100', 18));

    const balance = await honestAsset.balanceOf(namedAccounts.dummy1.address);
    expect(balance).to.equal(utils.parseUnits('100', 18));

    await proxyAdmin.revokeProxyRole(honestAsset.address, role, namedAccounts.dummy1.address);
  });

  it('burn without authorized, revert', async () => {
    await expect(honestAsset.burn(namedAccounts.dummy1.address, utils.parseUnits('100', 18))).to.reverted;
  });

  it('burn insufficient balance, revert', async () => {
    await proxyAdmin.grantProxyRole(honestAsset.address, role, namedAccounts.dummy1.address);

    await expect(honestAsset.burn(namedAccounts.dummy1.address, utils.parseUnits('200', 18))).to.reverted;

    const balance = await honestAsset.balanceOf(namedAccounts.dummy1.address);
    expect(balance).to.equal(utils.parseUnits('100', 18));
  });

  it('burn 100 of dummy', async () => {
    const result = await honestAsset.callStatic.burn(namedAccounts.dummy1.address, utils.parseUnits('100', 18));
    expect(result).to.equal(true);
    await honestAsset.burn(namedAccounts.dummy1.address, utils.parseUnits('100', 18));

    const balance = await honestAsset.balanceOf(namedAccounts.dummy1.address);
    expect(balance).to.equal(0);

    await proxyAdmin.revokeProxyRole(honestAsset.address, role, namedAccounts.dummy1.address);
  });
});
