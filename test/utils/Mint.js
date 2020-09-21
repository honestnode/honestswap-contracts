const BN = require('bn.js');

const MockDAI = artifacts.require('MockDAI');
const MockUSDT = artifacts.require('MockUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockTUSD = artifacts.require('MockTUSD');
const YearnV2Integration = artifacts.require('YearnV2Integration');
const HonestSavings = artifacts.require('HonestSavings');

contract('Mint', async (accounts) => {

  let dai, tusd, usdc, usdt, yearn, savings;
  const a10 = accounts[9];

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
    /*
    deployed dai: 0x1253B3D742606a9F3855f7e5d9e738099e033466
deployed tusd: 0xC7974997FEDfFAf99E408603A1b7d4d287065EBa
deployed usdc: 0xC14Ec97F5dee9D93900C78074778D1ED73B2B73f
deployed usdt: 0xbDCc29a8634635d60332aD192C7E256377bEE795
     */
    dai = await MockDAI.at('0x1253B3D742606a9F3855f7e5d9e738099e033466');
    tusd = await MockTUSD.at('0xC7974997FEDfFAf99E408603A1b7d4d287065EBa');
    usdc = await MockUSDC.at('0xC14Ec97F5dee9D93900C78074778D1ED73B2B73f');
    usdt = await MockUSDT.at('0xbDCc29a8634635d60332aD192C7E256377bEE795');
    savings = await HonestSavings.at('0x584c250D1AF1a655E1556400968c9C3Aef5F25d8');
    yearn = await YearnV2Integration.at('0x3055C4e1622F57FCF76079296D4b7ceD19d95d75');
    //console.log(await savings.investmentIntegrationContract());
  };

  before(async () => {
    await createContract();
  });

  // describe('to user', async () => {
  //   it ('', async () => {
  //     await dai.mint(a10, shift(100));
  //     await tusd.mint(a10, shift(100));
  //     await usdc.mint(a10, shift(100, 6));
  //     await usdt.mint(a10, shift(100, 6));
  //   });
  // });

  describe('yearn', async () => {
    it ('', async () => {
      await yearn.addWhitelisted('0x584c250D1AF1a655E1556400968c9C3Aef5F25d8');
      console.log('add white list admin');
    });
  });
});