import {ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract} from 'ethers';
import {honestAssetDeployer} from '../scripts/HonestAsset.deploy';
import {honestConfigurationDeployer} from '../scripts/HonestConfiguration.deploy';
import {honestFeeDeployer} from '../scripts/HonestFee.deploy';

describe('HonestFee', () => {
  let supervisor: string, dummy: string, honestAsset: Contract, honestConfiguration: Contract, fee: Contract,
    role: string;

  before(async function () {
    supervisor = await (await ethers.getSigners())[0].getAddress();
    dummy = await (await ethers.getSigners())[1].getAddress();
    honestAsset = await honestAssetDeployer.deployContracts();
    honestConfiguration = await honestConfigurationDeployer.deployContracts(honestAsset);
    fee = await honestFeeDeployer.deployContracts(honestConfiguration);
    role = await fee.SAVINGS();
  });

  it('save rewards', async () => {
    const assetManagerRole = await honestAsset.ASSET_MANAGER();
    await honestAsset.grantRole(assetManagerRole, supervisor);

    await honestAsset.mint(fee.address, ethers.utils.parseUnits('100', 18));
    const amount = await fee.totalFee();
    expect(amount).to.equal(ethers.utils.parseUnits('100', 18));

    await honestAsset.revokeRole(assetManagerRole, supervisor);
  });

  it('reward without authorization', async () => {
    await expect(fee.reward(dummy, ethers.utils.parseUnits('100', 18))).to.reverted;
  });

  it('reward insufficient balance', async () => {
    await expect(fee.reward(dummy, ethers.utils.parseUnits('101', 18))).to.reverted;
  });

  it('reward', async () => {
    await fee.grantRole(role, supervisor);

    await fee.reward(dummy, ethers.utils.parseUnits('100', 18));

    const balance = await honestAsset.balanceOf(dummy);
    expect(balance).to.equal(ethers.utils.parseUnits('100', 18));

    await fee.revokeRole(role, supervisor);
  });
});
