const BN = require('bn.js');
const {expectRevert} = require('@openzeppelin/test-helpers');
const ChainlinkIntegration = artifacts.require('ChainlinkIntegration');
const HonestBonus = artifacts.require('HonestBonus');

const MockDAI = artifacts.require('MockDAI');
const MockUSDT = artifacts.require('MockUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockTUSD = artifacts.require('MockTUSD');

contract('', async () => {

  let dai, tusd, usdc, usdt, chainlink, bonus;

  const shift = (value, offset = 18) => {
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
    chainlink = await ChainlinkIntegration.deployed();
    bonus = await HonestBonus.new();
    await bonus.initialize(chainlink.address);
  };

  before(async () => {
    await createContract();
  });

  describe('calculate', async () => {
    it('single', async () => {
      let b = await bonus.calculateBonus(dai.address, shift(1000), shift(1, 15));
      expect(b.toString('hex')).equal(shift(13).toString('hex'));
      b = await bonus.calculateBonus(tusd.address, shift(1000), shift(1, 15));
      expect(b.toString('hex')).equal(shift(2).toString('hex'));
      b = await bonus.calculateBonus(usdc.address, shift(100, 6), shift(1, 15));
      expect(b.toString('hex')).equal(shift(0).toString('hex'));
      b = await bonus.calculateBonus(usdt.address, shift(100, 6), shift(1, 15));
      expect(b.toString('hex')).equal(shift(15, 17).toString('hex'));
    });

    it('multiple', async () => {
      /*
       * assets: [dai, tusd, usdc, usdt]
       * amounts: [1000, 1000, 100, 100],
       * prices: [1.014, 1.003, 0.96, 1.016],
       * fee: 0.1%
       * expected: [13e18, 2e18, 0, 15e17]
       */
      const bonuses = await bonus.calculateBonuses([dai.address, tusd.address, usdc.address, usdt.address], [shift(1000), shift(1000), shift(100, 6), shift(100, 6)], shift(1, 15));
      expect(bonuses.toString('hex')).equal(shift(165, 17).toString('hex'));
    });
  });
});