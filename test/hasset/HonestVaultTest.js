const {expectRevert} = require('@openzeppelin/test-helpers');
const {BigNumbers, Constants} = require('../common/utils');
const HonestVault = artifacts.require('HonestVault');
const HonestAsset = artifacts.require('HonestAsset');
const MockDAI = artifacts.require('MockDAI');
const MockTUSD = artifacts.require('MockTUSD');
const MockUSDC = artifacts.require('MockUSDC');
const MockUSDT = artifacts.require('MockUSDT');
const MockHonestSavings = artifacts.require('MockHonestSavings');

contract('HonestVault', async (accounts) => {

  const dummy1 = accounts[1];
  let vault, hAsset, dai, tusd, usdc, usdt, savings;

  const createContracts = async () => {
    hAsset = await HonestAsset.deployed();
    dai = await MockDAI.deployed();
    tusd = await MockTUSD.deployed();
    usdc = await MockUSDC.deployed();
    usdt = await MockUSDT.deployed();
    savings = await MockHonestSavings.new();
    vault = await HonestVault.new();
    await vault.initialize(hAsset.address, savings.address, [dai.address, tusd.address, usdc.address, usdt.address]);
  };

  before(async () => {
    await createContracts();
  });

  describe('assets', async () => {

    it('add asset', async () => {
      let assets = await vault.basketAssets();
      const count = assets[0].length;

      expectRevert.unspecified(
        vault.addBasketAsset(Constants.VOID_ADDRESS),
      );

      await vault.addBasketAsset(hAsset.address);
      assets = await vault.basketAssets();

      expect(assets[0].length).equal(count + 1);
    });

    it('remove asset', async () => {
      let assets = await vault.basketAssets();
      const count = assets[0].length;

      expectRevert.unspecified(
        vault.removeBasketAsset(Constants.VOID_ADDRESS),
      );

      await vault.removeBasketAsset(hAsset.address);
      assets = await vault.basketAssets();

      expect(assets[0].length).equal(count - 1);

      expectRevert.unspecified(
        vault.removeBasketAsset(hAsset.address),
      );
    });

    it('deactivate asset', async () => {
      let assets = await vault.basketAssets();

      expectRevert.unspecified(
        vault.deactivateBasketAsset(Constants.VOID_ADDRESS),
      );

      expectRevert.unspecified(
        vault.deactivateBasketAsset(hAsset.address),
      );

      await vault.deactivateBasketAsset(assets[0][0]);
      assets = await vault.basketAssets();

      expect(assets[1][0]).equal(false);
    });

    it('activate asset', async () => {
      let assets = await vault.basketAssets();

      expectRevert.unspecified(
        vault.activateBasketAsset(Constants.VOID_ADDRESS),
      );

      expectRevert.unspecified(
        vault.activateBasketAsset(hAsset.address),
      );

      await vault.activateBasketAsset(assets[0][0]);
      assets = await vault.basketAssets();

      expect(assets[1][0]).equal(true);
    });
  });

  describe('distribute', async () => {
    it ('proportion only vault', async () => {
      dai.mint(vault.address, BigNumbers.shift(100));
      tusd.mint(vault.address, BigNumbers.shift(100));
      usdc.mint(vault.address, BigNumbers.shift(100, 6));
      usdt.mint(vault.address, BigNumbers.shift(100, 6));

      let daiBalance = await dai.balanceOf(dummy1);
      let tusdBalance = await tusd.balanceOf(dummy1);
      let usdcBalance = await usdc.balanceOf(dummy1);
      let usdtBalance = await usdt.balanceOf(dummy1);

      await vault.distributeProportionally(dummy1, BigNumbers.shift(400), 0);

      daiBalance = (await dai.balanceOf(dummy1)).sub(daiBalance);
      tusdBalance = (await tusd.balanceOf(dummy1)).sub(tusdBalance);
      usdcBalance = (await usdc.balanceOf(dummy1)).sub(usdcBalance);
      usdtBalance = (await usdt.balanceOf(dummy1)).sub(usdtBalance);

      expect(daiBalance.toString()).equal(BigNumbers.shift(100).toString());
      expect(tusdBalance.toString()).equal(BigNumbers.shift(100).toString());
      expect(usdcBalance.toString()).equal(BigNumbers.shift(100, 6).toString());
      expect(usdtBalance.toString()).equal(BigNumbers.shift(100, 6).toString());

      await dai.burn(dummy1, BigNumbers.shift(100));
      await tusd.burn(dummy1, BigNumbers.shift(100));
      await usdc.burn(dummy1, BigNumbers.shift(100, 6));
      await usdt.burn(dummy1, BigNumbers.shift(100, 6));
    });

    it('proportion with savings', async () => {
      tusd.mint(vault.address, BigNumbers.shift(100));
      usdc.mint(vault.address, BigNumbers.shift(100, 6));

      dai.mint(savings.address, BigNumbers.shift(100));
      usdt.mint(savings.address, BigNumbers.shift(100, 6));
      await savings.mock(dai.address, BigNumbers.shift(100));
      await savings.mock(usdt.address, BigNumbers.shift(100));

      let daiBalance = await dai.balanceOf(dummy1);
      let tusdBalance = await tusd.balanceOf(dummy1);
      let usdcBalance = await usdc.balanceOf(dummy1);
      let usdtBalance = await usdt.balanceOf(dummy1);

      await vault.distributeProportionally(dummy1, BigNumbers.shift(200), 0);

      daiBalance = (await dai.balanceOf(dummy1)).sub(daiBalance);
      tusdBalance = (await tusd.balanceOf(dummy1)).sub(tusdBalance);
      usdcBalance = (await usdc.balanceOf(dummy1)).sub(usdcBalance);
      usdtBalance = (await usdt.balanceOf(dummy1)).sub(usdtBalance);

      expect(daiBalance.toString()).equal(BigNumbers.shift(50).toString());
      expect(tusdBalance.toString()).equal(BigNumbers.shift(50).toString());
      expect(usdcBalance.toString()).equal(BigNumbers.shift(50, 6).toString());
      expect(usdtBalance.toString()).equal(BigNumbers.shift(50, 6).toString());

      await dai.burn(dummy1, BigNumbers.shift(50));
      await tusd.burn(dummy1, BigNumbers.shift(50));
      await usdc.burn(dummy1, BigNumbers.shift(50, 6));
      await usdt.burn(dummy1, BigNumbers.shift(50, 6));

      await dai.burn(savings.address, BigNumbers.shift(50));
      await tusd.burn(savings.address, BigNumbers.shift(50));
      await usdc.burn(savings.address, BigNumbers.shift(50, 6));
      await usdt.burn(savings.address, BigNumbers.shift(50, 6));
    });

    it('manual only vault', async () => {
      dai.mint(vault.address, BigNumbers.shift(100));
      tusd.mint(vault.address, BigNumbers.shift(100));
      usdc.mint(vault.address, BigNumbers.shift(100, 6));
      usdt.mint(vault.address, BigNumbers.shift(100, 6));

      let daiBalance = await dai.balanceOf(dummy1);
      let tusdBalance = await tusd.balanceOf(dummy1);
      let usdcBalance = await usdc.balanceOf(dummy1);
      let usdtBalance = await usdt.balanceOf(dummy1);

      await vault.distributeManually(dummy1,
        [dai.address, tusd.address, usdc.address, usdt.address],
        [BigNumbers.shift(100), BigNumbers.shift(100), BigNumbers.shift(100, 6), BigNumbers.shift(100, 6)],
        0
      );

      daiBalance = (await dai.balanceOf(dummy1)).sub(daiBalance);
      tusdBalance = (await tusd.balanceOf(dummy1)).sub(tusdBalance);
      usdcBalance = (await usdc.balanceOf(dummy1)).sub(usdcBalance);
      usdtBalance = (await usdt.balanceOf(dummy1)).sub(usdtBalance);

      expect(daiBalance.toString()).equal(BigNumbers.shift(100).toString());
      expect(tusdBalance.toString()).equal(BigNumbers.shift(100).toString());
      expect(usdcBalance.toString()).equal(BigNumbers.shift(100, 6).toString());
      expect(usdtBalance.toString()).equal(BigNumbers.shift(100, 6).toString());

      await dai.burn(dummy1, BigNumbers.shift(100));
      await tusd.burn(dummy1, BigNumbers.shift(100));
      await usdc.burn(dummy1, BigNumbers.shift(100, 6));
      await usdt.burn(dummy1, BigNumbers.shift(100, 6));
    });

    it('manual with savings', async () => {
      tusd.mint(vault.address, BigNumbers.shift(100));
      usdc.mint(vault.address, BigNumbers.shift(100, 6));

      dai.mint(savings.address, BigNumbers.shift(100));
      usdt.mint(savings.address, BigNumbers.shift(100, 6));
      await savings.mock(dai.address, BigNumbers.shift(100));
      await savings.mock(usdt.address, BigNumbers.shift(100));

      let daiBalance = await dai.balanceOf(dummy1);
      let tusdBalance = await tusd.balanceOf(savings.address);
      let usdcBalance = await usdc.balanceOf(savings.address);
      let usdtBalance = await usdt.balanceOf(dummy1);

      await vault.distributeManually(dummy1,
        [dai.address, usdt.address],
        [BigNumbers.shift(100), BigNumbers.shift(100, 6)],
        0
      );

      daiBalance = (await dai.balanceOf(dummy1)).sub(daiBalance);
      tusdBalance = (await tusd.balanceOf(savings.address)).sub(tusdBalance);
      usdcBalance = (await usdc.balanceOf(savings.address)).sub(usdcBalance);
      usdtBalance = (await usdt.balanceOf(dummy1)).sub(usdtBalance);

      expect(daiBalance.toString()).equal(BigNumbers.shift(100).toString());
      expect(tusdBalance.toString()).equal(BigNumbers.shift(100).toString());
      expect(usdcBalance.toString()).equal(BigNumbers.shift(100, 6).toString());
      expect(usdtBalance.toString()).equal(BigNumbers.shift(100, 6).toString());

      await dai.burn(dummy1, BigNumbers.shift(100));
      await tusd.burn(savings.address, BigNumbers.shift(100));
      await usdc.burn(savings.address, BigNumbers.shift(100, 6));
      await usdt.burn(dummy1, BigNumbers.shift(100, 6));

    });
  });
});