const {Deployer, Constants}  = require('../test/common/utils');

const YearnV2Integration = artifacts.require('YearnV2Integration');
const ChainlinkIntegration = artifacts.require('ChainlinkIntegration');
const MockDAI = artifacts.require('MockDAI');
const MockUSDT = artifacts.require('MockUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockTUSD = artifacts.require('MockTUSD');
const MockYDAI = artifacts.require('MockYDAI');
const MockYUSDT = artifacts.require('MockYUSDT');
const MockYUSDC = artifacts.require('MockYUSDC');
const MockYTUSD = artifacts.require('MockYTUSD');
const MockETH2USDFeeds = artifacts.require('MockETH2USDFeeds');
const MockDAI2USDFeeds = artifacts.require('MockDAI2USDFeeds');
const MockTUSD2ETHFeeds = artifacts.require('MockTUSD2ETHFeeds');
const MockUSDC2ETHFeeds = artifacts.require('MockUSDC2ETHFeeds');
const MockUSDT2ETHFeeds = artifacts.require('MockUSDT2ETHFeeds');

module.exports = function (deployer, network, accounts) {

  deployer.then(async () => {

    const dai = await MockDAI.deployed();
    const tusd = await MockTUSD.deployed();
    const usdc = await MockUSDC.deployed();
    const usdt = await MockUSDT.deployed();

    const yDAI = await MockYDAI.deployed();
    const yTUSD = await MockYTUSD.deployed();
    const yUSDC = await MockYUSDC.deployed();
    const yUSDT = await MockYUSDT.deployed();

    const ethFeeds = await Deployer.deploy(deployer, MockETH2USDFeeds);
    const daiFeeds = await Deployer.deploy(deployer, MockDAI2USDFeeds);
    const tusdFeeds = await Deployer.deploy(deployer, MockTUSD2ETHFeeds);
    const usdcFeeds = await Deployer.deploy(deployer, MockUSDC2ETHFeeds);
    const usdtFeeds = await Deployer.deploy(deployer, MockUSDT2ETHFeeds);

    const chainlink = await Deployer.deploy(deployer, ChainlinkIntegration);
    const yearn = await Deployer.deploy(deployer, YearnV2Integration);

    console.log('4.integration deployed ==>');
    console.log(`> MockETH2USDFeeds:       ${ethFeeds.address}`);
    console.log(`> MockDAI2USDFeeds:       ${daiFeeds.address}`);
    console.log(`> MockTUSD2ETHFeeds:      ${tusdFeeds.address}`);
    console.log(`> MockUSDC2ETHFeeds:      ${usdcFeeds.address}`);
    console.log(`> MockUSDT2ETHFeeds:      ${usdtFeeds.address}`);
    console.log(`> ChainlinkIntegration:   ${chainlink.address}`);
    console.log(`> YearnV2Integration:     ${yearn.address}`);
    console.log();

    return Promise.all([
      chainlink.initialize(
        [0, 0, 1, 1, 1],
        [Constants.VOID_ADDRESS, dai.address, tusd.address, usdc.address, usdt.address],
        [ethFeeds.address, daiFeeds.address, tusdFeeds.address, usdcFeeds.address, usdtFeeds.address]),
      yearn.initialize(
        [dai.address, tusd.address, usdc.address, usdt.address],
        [yDAI.address, yTUSD.address, yUSDC.address, yUSDT.address])
    ]);
  });
};

