const {expectRevert} = require('@openzeppelin/test-helpers');
const {BigNumbers, Constants} = require('../common/utils');

const HonestVault = artifacts.require('HonestVault');
const HonestAsset = artifacts.require('HonestAsset');
const HonestAssetManager = artifacts.require('HonestAssetManager');
const HonestFee = artifacts.require('HonestFee');
const MockDAI = artifacts.require('MockDAI');
const MockTUSD = artifacts.require('MockTUSD');
const MockUSDC = artifacts.require('MockUSDC');
const MockUSDT = artifacts.require('MockUSDT');

contract('HonestAsset', async (accounts) => {

  const supervisor = accounts[0];
  const dummy1 = accounts[1];
  const dummy2 = accounts[2];
  const dummy3 = accounts[3];
  const dummy4 = accounts[4];
  let hAsset, vault, assetManager, fee, dai, tusd, usdc, usdt;

  const createContracts = async () => {
    hAsset = await HonestAsset.deployed();
    vault = await HonestVault.deployed();
    assetManager = await HonestAssetManager.deployed();
    fee = await HonestFee.deployed();
    dai = await MockDAI.deployed();
    tusd = await MockTUSD.deployed();
    usdc = await MockUSDC.deployed();
    usdt = await MockUSDT.deployed();
  };

  before(async () => {
    await createContracts();
  });

  describe('mint', async () => {
    it('common', async () => {
      await dai.mint(dummy1, BigNumbers.shift(100));
      await usdt.mint(dummy1, BigNumbers.shift(100, 6));

      let daiBalance = await dai.balanceOf(dummy1);
      let usdtBalance = await usdt.balanceOf(dummy1);
      let hAssetBalance = await hAsset.balanceOf(dummy1);

      await dai.approve(assetManager.address, BigNumbers.shift(100), {from: dummy1});
      await usdt.approve(assetManager.address, BigNumbers.shift(100, 6), {from: dummy1});

      await assetManager.mint([dai.address, usdt.address], [BigNumbers.shift(100), BigNumbers.shift(100, 6)], {from: dummy1});

      daiBalance = daiBalance.sub(await dai.balanceOf(dummy1));
      usdtBalance = usdtBalance.sub(await usdt.balanceOf(dummy1));
      hAssetBalance = (await hAsset.balanceOf(dummy1)).sub(hAssetBalance);

      expect(daiBalance.toString()).equal(BigNumbers.shift(100).toString());
      expect(usdtBalance.toString()).equal(BigNumbers.shift(100, 6).toString());
      expect(hAssetBalance.toString()).equal(BigNumbers.shift(200).toString());

      await dai.burn(vault.address, BigNumbers.shift(100).toString());
      await usdt.burn(vault.address, BigNumbers.shift(100, 6).toString());
      await hAsset.approve(supervisor, BigNumbers.shift(200).toString(), {from: dummy1});
      await hAsset.burn(dummy1, BigNumbers.shift(200).toString());
    });
  });

  describe('redeem', async () => {

    it('proportion', async () => {
      await tusd.mint(vault.address, BigNumbers.shift(100));
      await usdc.mint(vault.address, BigNumbers.shift(100, 6));
      await hAsset.mint(dummy2, BigNumbers.shift(200));

      let tusdBalance = await tusd.balanceOf(dummy2);
      let usdcBalance = await usdc.balanceOf(dummy2);
      let hAssetBalance = await hAsset.balanceOf(dummy2);

      await hAsset.approve(assetManager.address, BigNumbers.shift(200), {from: dummy2});

      await assetManager.redeemProportionally(BigNumbers.shift(200), {from: dummy2});

      tusdBalance = (await tusd.balanceOf(dummy2)).sub(tusdBalance);
      usdcBalance = (await usdc.balanceOf(dummy2)).sub(usdcBalance);
      hAssetBalance = hAssetBalance.sub(await hAsset.balanceOf(dummy2));

      expect(tusdBalance.toString()).equal(BigNumbers.shift(100).toString());
      expect(usdcBalance.toString()).equal(BigNumbers.shift(100, 6).toString());
      expect(hAssetBalance.toString()).equal(BigNumbers.shift(200).toString());

      await tusd.burn(dummy2, BigNumbers.shift(100).toString());
      await usdc.burn(dummy2, BigNumbers.shift(100, 6).toString());
    });

    it('manual', async () => {
      await dai.mint(vault.address, BigNumbers.shift(100));
      await tusd.mint(vault.address, BigNumbers.shift(100));
      await usdc.mint(vault.address, BigNumbers.shift(100, 6));
      await usdt.mint(vault.address, BigNumbers.shift(100, 6));
      await hAsset.mint(dummy2, BigNumbers.shift(200));

      let daiBalance = await dai.balanceOf(dummy2);
      let tusdBalance = await tusd.balanceOf(vault.address);
      let usdcBalance = await usdc.balanceOf(vault.address);
      let usdtBalance = await usdt.balanceOf(dummy2);
      let hAssetBalance = await hAsset.totalSupply();

      await hAsset.approve(assetManager.address, BigNumbers.shift(200), {from: dummy2});

      await assetManager.redeemManually([dai.address, usdt.address], [BigNumbers.shift(100), BigNumbers.shift(100, 6)], {from: dummy2});

      daiBalance = (await dai.balanceOf(dummy2)).sub(daiBalance);
      tusdBalance = tusdBalance.sub(await tusd.balanceOf(vault.address));
      usdcBalance = usdcBalance.sub(await usdc.balanceOf(vault.address));
      usdtBalance = (await usdt.balanceOf(dummy2)).sub(usdtBalance);
      const feeBalance = await hAsset.balanceOf(fee.address);
      hAssetBalance = hAssetBalance.add(feeBalance).sub(await hAsset.totalSupply());

      expect(daiBalance.toString()).equal(BigNumbers.shift(100).toString());
      expect(tusdBalance.toString()).equal(BigNumbers.shift(0).toString());
      expect(usdcBalance.toString()).equal(BigNumbers.shift(0).toString());
      expect(usdtBalance.toString()).equal(BigNumbers.shift(100, 6).toString());
      expect(hAssetBalance.toString()).equal(BigNumbers.shift(200).toString());

      await dai.burn(dummy2, BigNumbers.shift(100).toString());
      await tusd.burn(vault.address, BigNumbers.shift(100).toString());
      await usdc.burn(vault.address, BigNumbers.shift(100, 6).toString());
      await usdt.burn(dummy2, BigNumbers.shift(100, 6).toString());
    });
  });

  describe('swap', async () => {
    it('common', async () => {
      await dai.mint(vault.address, BigNumbers.shift(100));
      await usdt.mint(dummy3, BigNumbers.shift(100, 6));

      let daiBalance = await dai.balanceOf(dummy3);
      let usdtBalance = await usdt.balanceOf(dummy3);

      await usdt.approve(assetManager.address, BigNumbers.shift(100, 6), {from: dummy3});

      await assetManager.swap(usdt.address, dai.address, BigNumbers.shift(100, 6), {from: dummy3});

      daiBalance = (await dai.balanceOf(dummy3)).sub(daiBalance);
      usdtBalance = usdtBalance.sub(await usdt.balanceOf(dummy3));

      expect(daiBalance.toString()).equal(BigNumbers.shift(999, 17).toString());
      expect(usdtBalance.toString()).equal(BigNumbers.shift(100, 6).toString());

      await dai.burn(dummy3, BigNumbers.shift(999, 17).toString());
      await usdt.burn(vault.address, BigNumbers.shift(100, 6).toString());
      await dai.burn(vault.address, BigNumbers.shift(1, 17).toString());
    });
  });

  describe('deposit & withdraw', async () => {

    it('deposit', async () => {
      await dai.mint(vault.address, BigNumbers.shift(100));
      await tusd.mint(vault.address, BigNumbers.shift(100));
      await usdc.mint(vault.address, BigNumbers.shift(100, 6));
      await usdt.mint(vault.address, BigNumbers.shift(100, 6));
      await hAsset.mint(supervisor, BigNumbers.shift(200));

      let daiBalance = await dai.balanceOf(dummy4);
      let tusdBalance = await tusd.balanceOf(dummy4);
      let usdcBalance = await usdc.balanceOf(dummy4);
      let usdtBalance = await usdt.balanceOf(dummy4);
      let hAssetBalance = await hAsset.balanceOf(assetManager.address);

      await hAsset.approve(assetManager.address, BigNumbers.shift(200), {from: supervisor});
      await assetManager.deposit(dummy4, BigNumbers.shift(200), {from: supervisor});

      daiBalance = (await dai.balanceOf(dummy4)).sub(daiBalance);
      tusdBalance = (await tusd.balanceOf(dummy4)).sub(tusdBalance);
      usdcBalance = (await usdc.balanceOf(dummy4)).sub(usdcBalance);
      usdtBalance = (await usdt.balanceOf(dummy4)).sub(usdtBalance);
      hAssetBalance = (await hAsset.balanceOf(assetManager.address)).sub(hAssetBalance);

      expect(daiBalance.toString()).equal(BigNumbers.shift(50).toString());
      expect(tusdBalance.toString()).equal(BigNumbers.shift(50).toString());
      expect(usdcBalance.toString()).equal(BigNumbers.shift(50, 6).toString());
      expect(usdtBalance.toString()).equal(BigNumbers.shift(50, 6).toString());
      expect(hAssetBalance.toString()).equal(BigNumbers.shift(200).toString());
    });

    it('withdraw', async () => {

      await dai.mint(supervisor, BigNumbers.shift(110));
      await tusd.mint(supervisor, BigNumbers.shift(110));
      await usdc.mint(supervisor, BigNumbers.shift(110, 6));
      await usdt.mint(supervisor, BigNumbers.shift(110, 6));
      await hAsset.mint(assetManager.address, BigNumbers.shift(400));

      let hAssetBalance = await hAsset.balanceOf(dummy4);

      //(address to, address[] calldata assets, uint[] calldata amounts, uint interests)
      dai.approve(assetManager.address, BigNumbers.shift(110));
      tusd.approve(assetManager.address, BigNumbers.shift(110));
      usdc.approve(assetManager.address, BigNumbers.shift(110, 6));
      usdt.approve(assetManager.address, BigNumbers.shift(110, 6));

      await assetManager.withdraw(dummy4,
        [dai.address, tusd.address, usdc.address, usdt.address],
        [BigNumbers.shift(110), BigNumbers.shift(110), BigNumbers.shift(110, 6), BigNumbers.shift(110, 6)],
        BigNumbers.shift(40));

      hAssetBalance = (await hAsset.balanceOf(dummy4)).sub(hAssetBalance);

      expect(hAssetBalance.toString()).equal(BigNumbers.shift(440).toString());
    });
  });
});