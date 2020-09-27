import {ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract} from 'ethers';
import {honestAssetDeployer} from '../scripts/HonestAsset.deploy';

describe('HonestAsset', () => {
  let supervisor: string, dummy: string, honestAsset: Contract, role: string;

  before(async function () {
    supervisor = await (await ethers.getSigners())[0].getAddress();
    dummy = await (await ethers.getSigners())[1].getAddress();
    honestAsset = honestAsset = await honestAssetDeployer.deployContracts();
    role = await honestAsset.ASSET_MANAGER();
  });

  it('mint without authorized, revert', async () => {
    await expect(honestAsset.mint(dummy, ethers.utils.parseUnits('100', 18))).to.reverted;
  });

  it('mint 100 to dummy', async () => {
    await honestAsset.grantRole(role, supervisor);

    const result = await honestAsset.callStatic.mint(dummy, ethers.utils.parseUnits('100', 18));
    expect(result).to.equal(true);
    await honestAsset.mint(dummy, ethers.utils.parseUnits('100', 18));

    const balance = await honestAsset.balanceOf(dummy);
    expect(balance).to.equal(ethers.utils.parseUnits('100', 18));

    await honestAsset.revokeRole(role, supervisor);
  });

  it('burn without authorized, revert', async () => {
    await expect(honestAsset.burn(dummy, ethers.utils.parseUnits('100', 18))).to.reverted;
  });

  it('burn insufficient balance, revert', async () => {
    await honestAsset.grantRole(role, supervisor);

    await expect(honestAsset.burn(dummy, ethers.utils.parseUnits('200', 18))).to.reverted;

    const balance = await honestAsset.balanceOf(dummy);
    expect(balance).to.equal(ethers.utils.parseUnits('100', 18));
  });

  it('burn 100 of dummy', async () => {
    const result = await honestAsset.callStatic.burn(dummy, ethers.utils.parseUnits('100', 18));
    expect(result).to.equal(true);
    await honestAsset.burn(dummy, ethers.utils.parseUnits('100', 18));

    const balance = await honestAsset.balanceOf(dummy);
    expect(balance).to.equal(0);

    await honestAsset.revokeRole(role, supervisor);
  });
});
