import {ethers, upgrades} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, ContractFactory} from 'ethers';
import {honestConfigurationDeployer} from '../../scripts/HonestConfiguration.deploy';

describe('ChainlinkIntegration', () => {

  let honestConfiguration: Contract, chainlinkIntegration: Contract;

  const deployContract = async (name: string, ...args: any[]): Promise<Contract> => {
    const contract: ContractFactory = await ethers.getContractFactory(name);
    return await contract.deploy(...args);
  };

  const deployContracts = async () => {
    honestConfiguration = await honestConfigurationDeployer.deployContracts();
    const ethPriceFeeds = await deployContract('MockETH2USDFeeds');
    const ChainlinkIntegration = await ethers.getContractFactory('ChainlinkIntegration');
    chainlinkIntegration =  await upgrades.deployProxy(ChainlinkIntegration,
      [honestConfiguration.address, ethPriceFeeds.address],
      {unsafeAllowCustomTypes: true});
  };

  before(async function () {
    await deployContracts();
  });

  it('get prices', async () => {
    const assets = await honestConfiguration.activeBasketAssets();
    const prices = await chainlinkIntegration.getPrices(assets);
    expect(prices.length).to.equal(assets.length);
    for(const asset of assets) {
      const price = await chainlinkIntegration.getPrice(asset);
      expect(price).to.gte(0);
    }
  });

  it('get unavailable price', async () => {
    await expect(chainlinkIntegration.getPrice('0x0000000000000000000000000000000000000000')).to.reverted;
    await expect(chainlinkIntegration.getPrice('0x1234567890abcdef1234567890abcdef12345678')).to.reverted;
  });

});