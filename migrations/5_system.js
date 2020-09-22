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
const MockYDAI = artifacts.require('MockYDAI');
const MockYUSDT = artifacts.require('MockYUSDT');
const MockYUSDC = artifacts.require('MockYUSDC');
const MockYTUSD = artifacts.require('MockYTUSD');

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
    const yDAI = await MockYDAI.deployed();
    const yTUSD = await MockYTUSD.deployed();
    const yUSDC = await MockYUSDC.deployed();
    const yUSDT = await MockYUSDT.deployed();
    const chainlink = await ChainlinkIntegration.deployed();
    const yearn = await YearnV2Integration.deployed();

    console.log('3.asset deployed ==>');
    console.log(`> HonestAsset:            ${hAsset.address}`);
    console.log(`> MockDAI:                ${dai.address}`);
    console.log(`> MockTUSD:               ${tusd.address}`);
    console.log(`> MockUSDC:               ${usdc.address}`);
    console.log(`> MockUSDT:               ${usdt.address}`);
    console.log(`> MockYDAI:               ${yDAI.address}`);
    console.log(`> MockYTUSD:              ${yTUSD.address}`);
    console.log(`> MockYUSDC:              ${yUSDC.address}`);
    console.log(`> MockYUSDT:              ${yUSDT.address}`);
    console.log();

    console.log('4.integration deployed ==>');
    console.log(`> ChainlinkIntegration:   ${chainlink.address}`);
    console.log(`> YearnV2Integration:     ${yearn.address}`);
    console.log();

    console.log('5.system deployed ==>');
    console.log(`> HonestFee:              ${fee.address}`);
    console.log(`> HonestBonus:            ${bonus.address}`);
    console.log(`> AssetManager:           ${hAssetManager.address}`);
    console.log(`> HonestVault:            ${vault.address}`);
    console.log(`> HonestSavings:          ${savings.address}`);
    console.log();

    console.log(`const hAssetAddress = '${hAsset.address}';`);
    console.log(`const hAssetManagerAddress = '${hAssetManager.address}';`);
    console.log(`const vaultAddress = '${vault.address}';`);
    console.log(`const savingsAddress = '${savings.address}';`);
    console.log(`const bonusAddress = '${bonus.address}';`);
    console.log(`const feeAddress = '${fee.address}';`);
    console.log();
    //
    // console.log(`asset = await HonestAsset.at('${hAsset.address}');`);
    // console.log(`manager = await HonestAssetManager.at('${hAssetManager.address}');`);
    // console.log(`vault = await HonestVault.at('${vault.address}');`);
    // console.log(`savings = await HonestSavings.at('${savings.address}');`);
    // console.log(`yearn = await YearnV2Integration.at('${yearn.address}');`);
    // console.log(`fee = await HonestFee.at('${fee.address}');`);
    // console.log(`bonus = await HonestBonus.at('${bonus.address}');`);
    // console.log(`dai = await MockDAI.at('${dai.address}');`);
    // console.log(`tusd = await MockUSDT.at('${tusd.address}');`);
    // console.log(`usdc = await MockUSDC.at('${usdc.address}');`);
    // console.log(`usdt = await MockTUSD.at('${usdt.address}');`);
    // console.log(`yDAI = await MockYDAI.at('${yDAI.address}');`);
    // console.log(`yTUSD = await MockYUSDT.at('${yTUSD.address}');`);
    // console.log(`yUSDC = await MockYUSDC.at('${yUSDC.address}');`);
    // console.log(`yUSDT = await MockYTUSD.at('${yUSDT.address}');`);

    return Promise.all([
      fee.initialize(hAsset.address),
      bonus.initialize(chainlink.address),
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
