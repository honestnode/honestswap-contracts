import {ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, Signer} from 'ethers';
import * as yTokenV2 from '../../artifacts/MockYTokenV2.json';
import {honestAssetDeployer} from '../../scripts/HonestAsset.deploy';
import {honestConfigurationDeployer} from '../../scripts/HonestConfiguration.deploy';
import {yearnV2IntegrationDeployer} from '../../scripts/integrations/YearnV2Integration.deploy';

describe('YearnV2Integration', () => {

  let supervisor: Signer, honestConfiguration: Contract, yearnV2Integration: Contract, savingsRole: string;

  const deployContracts = async () => {
    const honestAsset = await honestAssetDeployer.deployContracts();
    honestConfiguration = await honestConfigurationDeployer.deployContracts(honestAsset);
    yearnV2Integration = await yearnV2IntegrationDeployer.deployContracts(honestConfiguration);
  };

  before(async function () {
    supervisor = (await ethers.getSigners())[0];
    await deployContracts();
    savingsRole = await yearnV2Integration.SAVINGS();
  });

  it('invest without authorization', async () => {
    const assets = await honestConfiguration.activeBasketAssets();
    for (const asset of assets) {
      await expect(yearnV2Integration.invest(asset, ethers.utils.parseUnits('100', 18))).to.reverted;
    }
  });

  it('invest', async () => {
    await yearnV2Integration.grantRole(savingsRole, await supervisor.getAddress());

    const assets = await honestConfiguration.activeBasketAssets();
    for (const asset of assets) {
      const token = new Contract(asset, yTokenV2.abi, supervisor);
      const decimals = await token.decimals();
      await token.mint(await supervisor.getAddress(), ethers.utils.parseUnits('100', decimals));
      await token.approve(yearnV2Integration.address, ethers.utils.parseUnits('100', decimals));
      const price = await yearnV2Integration.priceOf(asset);
      const shares = ethers.utils.parseUnits('100', decimals + 18).div(price).mul(ethers.utils.parseUnits('1', 18 - decimals));
      await yearnV2Integration.invest(asset, ethers.utils.parseUnits('100', decimals));
      expect(await yearnV2Integration.shareOf(asset)).to.lte(shares);
    }

    await yearnV2Integration.revokeRole(savingsRole, await supervisor.getAddress());
  });

  it('collect without authorization', async () => {
    const assets = await honestConfiguration.activeBasketAssets();
    for (const asset of assets) {
      await expect(yearnV2Integration.collect(asset, ethers.utils.parseUnits('100', 18))).to.reverted;
    }
  });

  it('collect', async () => {
    await yearnV2Integration.grantRole(savingsRole, await supervisor.getAddress());

    const assets = await honestConfiguration.activeBasketAssets();
    for (const asset of assets) {
      const token = new Contract(asset, yTokenV2.abi, supervisor);
      const decimals = await token.decimals();
      const shares = await yearnV2Integration.shareOf(asset);
      await yearnV2Integration.collect(asset, shares);
      const balance = await token.balanceOf(await supervisor.getAddress());
      expect(balance).to.gte(ethers.utils.parseUnits('100', decimals));
    }

    await yearnV2Integration.revokeRole(savingsRole, await supervisor.getAddress());
  });
});