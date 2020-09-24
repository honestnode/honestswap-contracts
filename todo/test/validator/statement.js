const {BigNumbers, Constants} = require('../common/utils');

const HonestAsset = artifacts.require('HonestAsset');
const HonestAssetManager = artifacts.require('HonestAssetManager');
const HonestVault = artifacts.require('HonestVault');
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

contract('Statement', async (accounts) => {

  const dummy = accounts[9];

  let asset, manager, vault, savings, yearn, fee, bonus, dai, tusd, usdc, usdt, yDAI, yTUSD, yUSDC, yUSDT;

  const createContract = async () => {
    asset = await HonestAsset.at('0x8DBBb2b8bD8820209614d89957d710F0B93016c8');
    manager = await HonestAssetManager.at('0xB6e42332f2384ca71368026B95723AA9C46C66Ad');
    vault = await HonestVault.at('0x573C27e7751503Cf0C98aC62F7e05832e7f4bb8F');
    savings = await HonestSavings.at('0xF9122714A405aba4B07E82CDC3a4c763A36DcF9b');
    yearn = await YearnV2Integration.at('0x869045A2B7ce1Bbe68B8282C498c3c11c58790eD');
    fee = await HonestFee.at('0xD8F7FA7416d49732A62C726FcA67969aD899C5F6');
    bonus = await HonestBonus.at('0x829a05D84de1bECB5Ba97f354b4cF16a0BCFfAb2');
    dai = await MockDAI.at('0x5c76c32fbBb77d129ee09c618DcAe102BeAe057C');
    tusd = await MockUSDT.at('0xf3e4bc0783401b0ef647899931527d429bD2b15E');
    usdc = await MockUSDC.at('0x77B2621a27818d944dA1299C7286b772f68d17F3');
    usdt = await MockTUSD.at('0x13f9bBdD3B7fd9792e15304ca2619e0C81E83A14');
    yDAI = await MockYDAI.at('0x1280Ec259a82A27502b9604590367e0aD38b3357');
    yTUSD = await MockYUSDT.at('0xd662Ae84B465d307D470D28493E3d1aB0dF1b65f');
    yUSDC = await MockYUSDC.at('0xCf33dFab9ebC3E379cf1E7036EB38A4BC4539FF1');
    yUSDT = await MockYTUSD.at('0xDd8e13791c4EC63584bc8946291f9eE021137c8A');
  };

  before(async () => {
    await createContract();
  });

  describe('asset & basket assets', async () => {
    it('dummy', async () => {
      const balances = {
        asset: BigNumbers.unshift(await asset.balanceOf(dummy)),
        dai: BigNumbers.unshift(await dai.balanceOf(dummy)),
        tusd: BigNumbers.unshift(await tusd.balanceOf(dummy)),
        usdc: BigNumbers.unshift(await usdc.balanceOf(dummy), 6),
        usdt: BigNumbers.unshift(await usdt.balanceOf(dummy), 6)
      };
      console.log(balances);
    });

    it('vault', async () => {
      const balances = {
        asset: BigNumbers.unshift(await asset.balanceOf(manager.address)),
        dai: BigNumbers.unshift(await dai.balanceOf(vault.address)),
        tusd: BigNumbers.unshift(await tusd.balanceOf(vault.address)),
        usdc: BigNumbers.unshift(await usdc.balanceOf(vault.address), 6),
        usdt: BigNumbers.unshift(await usdt.balanceOf(vault.address), 6)
      };
      console.log(balances);
    });

    it('yearn', async () => {
      const balances = {
        dai: BigNumbers.unshift(await dai.balanceOf(yDAI.address)),
        tusd: BigNumbers.unshift(await tusd.balanceOf(yTUSD.address)),
        usdc: BigNumbers.unshift(await usdc.balanceOf(yUSDC.address), 6),
        usdt: BigNumbers.unshift(await usdt.balanceOf(yUSDT.address), 6)
      };
      console.log(balances);
    });
  });

  describe('savings', async () => {
    it('dummy', async () => {
      const statement = {
        shares: BigNumbers.unshift(await savings.sharesOf(dummy)),
        totalShares: BigNumbers.unshift(await savings.totalShares()),
        savings: BigNumbers.unshift(await savings.savingsOf(dummy)),
        totalSavings: BigNumbers.unshift(await savings.totalSavings()),
      };
      console.log(statement);
    });
  });
});
