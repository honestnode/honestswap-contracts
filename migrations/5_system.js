const {BigNumbers, Deployer}  = require('../test/common/utils');

const Nexus = artifacts.require('Nexus');
const HonestAsset = artifacts.require('HonestAsset');
const HonestAssetManager = artifacts.require('HonestAssetManager');
const HonestVault = artifacts.require('HonestVault');

const ChainlinkIntegration = artifacts.require('ChainlinkIntegration');
const YearnV2Integration = artifacts.require('YearnV2Integration');
const HonestBonus = artifacts.require('HonestBonus');
const HonestFee = artifacts.require('HonestFee');
const HonestSavings = artifacts.require('HonestSavings');
const MockDAI = artifacts.require('MockDAI');
const MockUSDT = artifacts.require('MockUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockTUSD = artifacts.require('MockTUSD');

module.exports = function (deployer) {

  deployer.then(async () => {

    const fee = await Deployer.deploy(deployer, HonestFee);
    const bonus = await Deployer.deploy(deployer, HonestBonus);

    const hAssetManager = await Deployer.deploy(deployer, HonestAssetManager);
    const vault = await Deployer.deploy(deployer, HonestVault);
    const savings = await Deployer.deploy(deployer, HonestSavings);

    const hAsset = await HonestAsset.deployed();
    const dai = await MockDAI.deployed();
    const tusd = await MockTUSD.deployed();
    const usdc = await MockUSDC.deployed();
    const usdt = await MockUSDT.deployed();
    const chainLink = await ChainlinkIntegration.deployed();
    const yearn = await YearnV2Integration.deployed();

    console.log('5.system deployed ==>');
    console.log(`> HonestFee:              ${fee.address}`);
    console.log(`> HonestBonus:            ${bonus.address}`);
    console.log(`> AssetManager:           ${hAssetManager.address}`);
    console.log(`> HonestVault:            ${vault.address}`);
    console.log(`> HonestSavings:          ${savings.address}`);
    console.log();

    return Promise.all([
      fee.initialize(hAsset.address),
      bonus.initialize(chainLink.address),
      hAssetManager.initialize(hAsset.address, vault.address, fee.address, bonus.address),
      vault.initialize(hAsset.address, savings.address, [dai.address, tusd.address, usdc.address, usdt.address]),
      savings.initialize(hAsset.address, hAssetManager.address, yearn.address, fee.address, bonus.address),
      yearn.addWhitelisted(savings.address),
      hAsset.addWhitelistAdmin(hAssetManager.address),
      vault.addWhitelistAdmin(hAssetManager.address),
      hAssetManager.addWhitelistAdmin(savings.address)
    ]);
  });
};
