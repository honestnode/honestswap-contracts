const Nexus = artifacts.require('Nexus');
const ChainLinkBAssetPrice = artifacts.require('ChainLinkBAssetPrice');
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

    const nexus = Nexus.deployed();
    const chainLink = ChainLinkBAssetPrice.deployed();
    const yearn = YearnV2Integration.deployed();
    const hAsset = HAsset.deployed();
    const basket = HonestBasket.deployed();
    const bonus = HonestBonus.deployed();
    const fee = HonestFee.deployed();
    const savings = HonestSavings.deployed();
    const validator = BAssetValidator.deployed();
    const dai = MockDAI.deployed();
    const tusd = MockTUSD.deployed();
    const usdc = MockUSDC.deployed();
    const usdt = MockUSDT.deployed();

    return Promise.all(
      fee.initialize(hAsset.address),
      bonus.initialize(chainLink.address),
      basket.initialize(nexus.address, hAsset.address, [dai.address, tusd.address, usdc.address, usdt.address],
        savings.address, fee.address, validator.address),
      savings.initialize(hAsset.address, basket.address, yearn.address, fee.address, bonus.address),
      hAsset.initialize('hUSD', 18, nexus.address, basket.address, savings.address, bonus.address, fee.address, validator.address)
    );
  });
};
