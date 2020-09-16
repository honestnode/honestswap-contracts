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
    it('bonus', async () => {
      /*
       * assets: [dai, tusd, usdc, usdt]
       * amounts: [1000, 1000, 100, 100],
       * prices: [1.014, 1.003, 0.96, 1.016],
       * fee: 0.1%
       * expected: [13e18, 2e18, 0, 15e17]
       */
      const bonuses = await bonus.calculateBonus([dai.address, tusd.address, usdc.address, usdt.address], [shift(1000), shift(1000), shift(100, 6), shift(100, 6)], shift(1, 15));
      expect(bonuses[0].toString('hex')).equal(shift(13).toString('hex'));
      expect(bonuses[1].toString('hex')).equal(shift(2).toString('hex'));
      expect(bonuses[2].toString('hex')).equal(shift(0).toString('hex'));
      expect(bonuses[3].toString('hex')).equal(shift(15, 17).toString('hex'));
    });
  });
});