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

    await deployer.deploy(MockDAI);
    await deployer.deploy(MockUSDT);
    await deployer.deploy(MockUSDC);
    await deployer.deploy(MockTUSD);

    const dai = await MockDAI.deployed();
    const tusd = await MockTUSD.deployed();
    const usdc = await MockUSDC.deployed();
    const usdt = await MockUSDT.deployed();

    await deployer.deploy(MockYDAI, dai.address);
    await deployer.deploy(MockYTUSD, tusd.address);
    await deployer.deploy(MockYUSDC, usdc.address);
    await deployer.deploy(MockYUSDT, usdt.address);

    const yDAI = await MockYDAI.deployed();
    const yTUSD = await MockYTUSD.deployed();
    const yUSDC = await MockYUSDC.deployed();
    const yUSDT = await MockYUSDT.deployed();

    await deployer.deploy(MockETH2USDFeeds);
    await deployer.deploy(MockDAI2USDFeeds);
    await deployer.deploy(MockTUSD2ETHFeeds);
    await deployer.deploy(MockUSDC2ETHFeeds);
    await deployer.deploy(MockUSDT2ETHFeeds);

    const ethFeeds = await MockETH2USDFeeds.deployed();
    const daiFeeds = await MockDAI2USDFeeds.deployed();
    const tusdFeeds = await MockTUSD2ETHFeeds.deployed();
    const usdcFeeds = await MockUSDC2ETHFeeds.deployed();
    const usdtFeeds = await MockUSDT2ETHFeeds.deployed();

    await deployer.deploy(ChainlinkIntegration);
    await deployer.deploy(YearnV2Integration);

    const chainlink = await ChainlinkIntegration.deployed();
    const yearn = await YearnV2Integration.deployed();

    return Promise.all([
      chainlink.initialize(
        [0, 0, 1, 1, 1],
        ['0x0000000000000000000000000000000000000000', dai.address, tusd.address, usdc.address, usdt.address],
        [ethFeeds.address, daiFeeds.address, tusdFeeds.address, usdcFeeds.address, usdtFeeds.address]),
      yearn.initialize(
        [dai.address, tusd.address, usdc.address, usdt.address],
        [yDAI.address, yTUSD.address, yUSDC.address, yUSDT.address])
    ]);
  });
};
