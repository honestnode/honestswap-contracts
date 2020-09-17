const Nexus = artifacts.require('Nexus');
const ChainlinkIntegration = artifacts.require('ChainlinkIntegration');
const YearnV2Integration = artifacts.require('YearnV2Integration');
const HonestBonus = artifacts.require('HonestBonus');
const HonestFee = artifacts.require('HonestFee');
const HonestBasket = artifacts.require('HonestBasket');
const HonestSavings = artifacts.require('HonestSavings');
const HAsset = artifacts.require('HAsset');
const BAssetValidator = artifacts.require('BAssetValidator');
const MockDAI = artifacts.require('MockDAI');
const MockUSDT = artifacts.require('MockUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockTUSD = artifacts.require('MockTUSD');

module.exports = function (deployer) {
  deployer.then(async () => {
    await deployer.deploy(HonestBonus);
    await deployer.deploy(HonestFee);

    await deployer.deploy(BAssetValidator);
    await deployer.deploy(HonestSavings);
    await deployer.deploy(HAsset);
    await deployer.deploy(HonestBasket);

    const nexus = await Nexus.deployed();
    const chainLink = await ChainlinkIntegration.deployed();
    const yearn = await YearnV2Integration.deployed();
    const hAsset = await HAsset.deployed();
    const basket = await HonestBasket.deployed();
    const bonus = await HonestBonus.deployed();
    const fee = await HonestFee.deployed();
    const savings = await HonestSavings.deployed();
    const validator = await BAssetValidator.deployed();
    const dai = await MockDAI.deployed();
    const tusd = await MockTUSD.deployed();
    const usdc = await MockUSDC.deployed();
    const usdt = await MockUSDT.deployed();

    return Promise.all([
      fee.initialize(hAsset.address),
      bonus.initialize(chainLink.address),
      basket.initialize(nexus.address, hAsset.address, [dai.address, tusd.address, usdc.address, usdt.address],
        savings.address, fee.address, validator.address),
      savings.initialize(hAsset.address, basket.address, yearn.address, fee.address, bonus.address),
      hAsset.initialize('hUSD', 'hUSD', nexus.address, basket.address, savings.address, bonus.address, fee.address, validator.address)
    ]);
  });
};
