const BN = require('bn.js');
const {expectRevert} = require('@openzeppelin/test-helpers');

const MockDAI = artifacts.require('MockDAI');
const MockUSDT = artifacts.require('MockUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockTUSD = artifacts.require('MockTUSD');
const MockETH2USDFeeds = artifacts.require('MockETH2USDFeeds');
const MockDAI2USDFeeds = artifacts.require('MockDAI2USDFeeds');
const MockTUSD2ETHFeeds = artifacts.require('MockTUSD2ETHFeeds');
const MockUSDC2ETHFeeds = artifacts.require('MockUSDC2ETHFeeds');
const MockUSDT2ETHFeeds = artifacts.require('MockUSDT2ETHFeeds');
const ChainlinkIntegration = artifacts.require('ChainlinkIntegration');

contract('ChainlinkIntegration', async () => {

  let dai, tusd, usdc, usdt, integration;

  const shift = (value, offset) => {
    if (offset === 0) {
      return new BN(value);
    } else if (offset > 0) {
      return new BN(value).mul(new BN(10).pow(new BN(offset)));
    } else {
      return new BN(value).div(new BN(10).pow(new BN(offset)));
    }
  }

  const createContract = async () => {
    dai = await MockDAI.deployed();
    tusd = await MockTUSD.deployed();
    usdc = await MockUSDC.deployed();
    usdt = await MockUSDT.deployed();
    integration = await ChainlinkIntegration.deployed();
  };

  before(async () => {
    await createContract();
  });

  describe('price', async () => {

    it('usd target prices', async () => {
      const price = await integration.getPrice(dai.address);
      expect(shift(1014, 15).toString('hex')).equal(price.toString('hex'));
    });

    it('eth target prices', async () => {
      let price = await integration.getPrice(tusd.address);
      expect(shift(1003, 15).toString('hex')).equal(price.toString('hex'));

      price = await integration.getPrice(usdc.address);
      expect(shift(1072, 15).toString('hex')).equal(price.toString('hex'));

      price = await integration.getPrice(usdt.address);
      expect(shift(1016, 15).toString('hex')).equal(price.toString('hex'));
    });

    it('not exist asset', async () => {
      await integration.deregister(0, dai.address);
      await expectRevert.unspecified(
        integration.getPrice(dai.address)
      );
    });

    it('remove eth price feeds', async () => {
      await integration.deregister(0, '0x0000000000000000000000000000000000000000');
      await expectRevert.unspecified(
        integration.getPrice(tusd.address)
      );
      await expectRevert.unspecified(
        integration.getPrice(usdc.address)
      );
      await expectRevert.unspecified(
        integration.getPrice(usdt.address)
      );
    });
  });
});