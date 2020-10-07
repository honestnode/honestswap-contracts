import {ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, Signer} from 'ethers';
import * as yTokenV2 from '../artifacts/MockYTokenV2.json';
import {honestAssetDeployer} from '../scripts/HonestAsset.deploy';
import {honestBonusDeployer} from '../scripts/HonestBonus.deploy';
import {honestConfigurationDeployer} from '../scripts/HonestConfiguration.deploy';
import {chainlinkIntegrationDeployer} from '../scripts/integrations/ChainlinkIntegration.deploy';

describe('HonestBonus', () => {
  let supervisor: Signer, dummy: string, honestConfiguration: Contract, bonus: Contract;

  before(async function () {
    supervisor = (await ethers.getSigners())[0];
    dummy = await (await ethers.getSigners())[1].getAddress();
    const honestAsset = await honestAssetDeployer.deployContracts();
    honestConfiguration = await honestConfigurationDeployer.deployContracts(honestAsset);
    const priceIntegration = await chainlinkIntegrationDeployer.deployContracts(honestConfiguration);
    bonus = await honestBonusDeployer.deployContracts(priceIntegration);
  });

  it('calculate single bonus', async () => {
    const assets = await honestConfiguration.activeBasketAssets();
    const rate = ethers.utils.parseUnits('1', 15);
    for (const asset of assets) {
      const y = await bonus.hasBonus(asset, rate);
      const value = await bonus.calculateBonus(asset, ethers.utils.parseUnits('100', 18), rate);
      if (y) {
        expect(value).to.gt(ethers.BigNumber.from('0'));
      } else {
        expect(value).to.equal(ethers.BigNumber.from('0'));
      }
    }
  });

  it('calculate multiple bonus', async () => {
    const assets = await honestConfiguration.activeBasketAssets();
    const rate = ethers.utils.parseUnits('1', 15);
    const amounts = [];
    for (const asset of assets) {
      const token = new Contract(asset, yTokenV2.abi, supervisor);
      const decimals = await token.decimals();
      amounts.push(ethers.utils.parseUnits('100', decimals));
    }
    const value = await bonus.calculateBonuses(assets, amounts, rate);
    expect(value).to.gte(ethers.BigNumber.from('0'));
  });

  it('add bonus without authorization', async () => {
    await expect(bonus.addBonus(dummy, ethers.utils.parseUnits('10', 18), ethers.utils.parseUnits('1', 18))).to.reverted;
  });

  it('add bonus of price 0', async () => {
    const assetManager = await bonus.ASSET_MANAGER();
    const supervisorAddress = await supervisor.getAddress();
    bonus.grantRole(assetManager, supervisorAddress);

    await bonus.addBonus(dummy, ethers.utils.parseUnits('10', 18), 0);
    expect(await bonus.bonusOf(dummy)).to.equal(ethers.BigNumber.from('0'));
    expect(await bonus.shareOf(dummy)).to.equal(ethers.BigNumber.from('0'));

    bonus.revokeRole(assetManager, supervisorAddress);
  });

  it('add bonus of price 0 to valid', async () => {
    const assetManager = await bonus.ASSET_MANAGER();
    const supervisorAddress = await supervisor.getAddress();
    bonus.grantRole(assetManager, supervisorAddress);

    await bonus.addBonus(dummy, ethers.utils.parseUnits('10', 18), ethers.utils.parseUnits('1', 18));
    expect(await bonus.bonusOf(dummy)).to.equal(ethers.utils.parseUnits('10', 18));
    expect(await bonus.shareOf(dummy)).to.equal(ethers.utils.parseUnits('10', 18));

    await bonus.addBonus(dummy, ethers.utils.parseUnits('12', 18), ethers.utils.parseUnits('1.2', 18));
    expect(await bonus.bonusOf(dummy)).to.equal(ethers.utils.parseUnits('22', 18));
    expect(await bonus.shareOf(dummy)).to.equal(ethers.utils.parseUnits('20', 18));

    bonus.revokeRole(assetManager, supervisorAddress);
  });


  it('reward bonus without authorization', async () => {
    await expect(bonus.reward(dummy, ethers.utils.parseUnits('10', 18), 0)).to.reverted;
  });

  it('reward bonus', async () => {
    const assetManager = await bonus.ASSET_MANAGER();
    const supervisorAddress = await supervisor.getAddress();
    bonus.grantRole(assetManager, supervisorAddress);

    let amount = await bonus.callStatic.reward(dummy, ethers.utils.parseUnits('1', 18));
    expect(amount).to.equal(ethers.BigNumber.from('0'));

    amount = await bonus.callStatic.reward(dummy, ethers.utils.parseUnits('1.3', 18));
    expect(amount).to.equal(ethers.utils.parseUnits('4', 18));

    await bonus.reward(dummy, ethers.utils.parseUnits('1.3', 18));

    amount = await bonus.callStatic.reward(dummy, ethers.utils.parseUnits('1.3', 18));
    expect(amount).to.equal(ethers.BigNumber.from('0'));

    bonus.revokeRole(assetManager, supervisorAddress);
  });
});
