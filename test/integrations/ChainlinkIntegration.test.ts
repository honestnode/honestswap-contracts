// import {expect} from 'chai';
// import {Contract, ContractFactory} from 'ethers';
// import {honestAssetDeployer} from '../../scripts/HonestAsset.deploy';
// import {honestConfigurationDeployer} from '../../scripts/HonestConfiguration.deploy';
// import {chainlinkIntegrationDeployer} from '../../scripts/integrations/ChainlinkIntegration.deploy';
//
// describe('ChainlinkIntegration', () => {
//
//   let honestConfiguration: Contract, chainlinkIntegration: Contract;
//
//   const deployContracts = async () => {
//     const honestAsset = await honestAssetDeployer.deployContracts();
//     honestConfiguration = await honestConfigurationDeployer.deployContracts(honestAsset);
//     chainlinkIntegration = await chainlinkIntegrationDeployer.deployContracts(honestConfiguration);
//   };
//
//   before(async function () {
//     await deployContracts();
//   });
//
//   it('get prices', async () => {
//     const assets = await honestConfiguration.activeBasketAssets();
//     const prices = await chainlinkIntegration.getPrices(assets);
//     expect(prices.length).to.equal(assets.length);
//     for(const asset of assets) {
//       const price = await chainlinkIntegration.getPrice(asset);
//       expect(price).to.gte(0);
//     }
//   });
//
//   it('get unavailable price', async () => {
//     await expect(chainlinkIntegration.getPrice('0x0000000000000000000000000000000000000000')).to.reverted;
//     await expect(chainlinkIntegration.getPrice('0x1234567890abcdef1234567890abcdef12345678')).to.reverted;
//   });
//
// });