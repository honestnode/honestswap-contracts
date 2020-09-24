const {BigNumbers, Deployer}  = require('../test/common/utils');

const HonestAsset = artifacts.require('HonestAsset');
const MockDAI = artifacts.require('MockDAI');
const MockUSDT = artifacts.require('MockUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockTUSD = artifacts.require('MockTUSD');
const MockYDAI = artifacts.require('MockYDAI');
const MockYUSDT = artifacts.require('MockYUSDT');
const MockYUSDC = artifacts.require('MockYUSDC');
const MockYTUSD = artifacts.require('MockYTUSD');

module.exports = (deployer, network, accounts) => {

  deployer.then(async () => {

    const hAsset = await Deployer.deploy(deployer, HonestAsset, 'Honest USD', 'hUSD');

    const dai = await Deployer.deploy(deployer, MockDAI);
    const tusd = await Deployer.deploy(deployer, MockTUSD);
    const usdc = await Deployer.deploy(deployer, MockUSDC);
    const usdt = await Deployer.deploy(deployer, MockUSDT);

    const yDAI = await Deployer.deploy(deployer, MockYDAI, dai.address);
    const yTUSD = await Deployer.deploy(deployer, MockYTUSD, tusd.address);
    const yUSDC = await Deployer.deploy(deployer, MockYUSDC, usdc.address);
    const yUSDT = await Deployer.deploy(deployer, MockYUSDT, usdt.address);

    return Promise.all([
      dai.mint(yDAI.address, BigNumbers.shift(1000)),
      tusd.mint(yTUSD.address, BigNumbers.shift(1000)),
      usdc.mint(yUSDC.address, BigNumbers.shift(1000, 6)),
      usdt.mint(yUSDT.address, BigNumbers.shift(1000, 6)),

      dai.mint(accounts[9], BigNumbers.shift(100)),
      tusd.mint(accounts[9], BigNumbers.shift(100)),
      usdc.mint(accounts[9], BigNumbers.shift(100, 6)),
      usdt.mint(accounts[9], BigNumbers.shift(100, 6)),
    ]);
  });
};
