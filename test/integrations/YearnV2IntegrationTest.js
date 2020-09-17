const BN = require('bn.js');
const MockDAI = artifacts.require('MockDAI');
const MockUSDT = artifacts.require('MockUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockTUSD = artifacts.require('MockTUSD');
const MockYDAI = artifacts.require('MockYDAI');
const MockYUSDT = artifacts.require('MockYUSDT');
const MockYUSDC = artifacts.require('MockYUSDC');
const MockYTUSD = artifacts.require('MockYTUSD');
const YearnV2Integration = artifacts.require('YearnV2Integration');

contract('YearnV2Integration', async (accounts) => {

  const owner = accounts[0];
  const investor1 = accounts[1];
  const investor2 = accounts[2];

  let dai, tusd, usdc, usdt, yDAI, yTUSD, yUSDC, yUSDT, integration;

  const d18 = (number) => {
    return new BN(number).mul(new BN(10).pow(new BN(18)));
  };

  const d6 = (number) => {
    return new BN(number).mul(new BN(10).pow(new BN(6)));
  };

  const createContract = async () => {
    dai = await MockDAI.deployed();
    tusd = await MockTUSD.deployed();
    usdc = await MockUSDC.deployed();
    usdt = await MockUSDT.deployed();
    yDAI = await MockYDAI.deployed();
    yTUSD = await MockYTUSD.deployed();
    yUSDC = await MockYUSDC.deployed();
    yUSDT = await MockYUSDT.deployed();
    integration = await YearnV2Integration.deployed();
  };

  before(async () => {
    await createContract();
  });

  describe('assets', async () => {

    it('add/remove assets', async () => {
      let assets = await integration.assets();
      expect(assets.length).equal(4);

      await integration.removeAsset(dai.address);
      assets = await integration.assets();
      expect(assets.length).equal(3);

      await integration.removeAsset(tusd.address);
      assets = await integration.assets();
      expect(assets.length).equal(2);
    });

    it ('duplicated add asset', async () => {
      await integration.addAsset(dai.address, yDAI.address);
      await integration.addAsset(tusd.address, yTUSD.address);
      let assets = await integration.assets();
      expect(assets.length).equal(4);

      await integration.addAsset(usdc.address, yUSDC.address);
      await integration.addAsset(usdt.address, yUSDT.address);
      assets = await integration.assets();
      expect(assets.length).equal(4);
    });
  });

  describe('invest and collect', async () => {

    it('dai 18 decimals', async () => {

      // TODO: should add expect expression
      const price = await integration.priceOf(dai.address);
      console.log('dai price: ', price.toString());

      await dai.mint(investor1, d18(100));
      await dai.mint(yDAI.address, d18(100));
      await integration.addWhitelisted(investor1);

      let pBalances = await integration.balanceOf(dai.address);
      console.log('current integration dai balance: ', pBalances.toString());

      await dai.approve(integration.address, d18(100), {from: investor1});
      const shares = await integration.invest.call(dai.address, d18(100), {from: investor1});
      console.log('shares of invest dai: ', shares.toString());

      await integration.invest(dai.address, d18(100), {from: investor1});
      let nBalances = await integration.balanceOf(dai.address);
      console.log('current integration dai balance: ', nBalances.toString());

      await integration.collect(dai.address, shares, {from: investor1});

      nBalances = await dai.balanceOf(investor1);
      console.log('current user dai balance: ', nBalances.toString());

      nBalances = await integration.balanceOf(dai.address);
      expect(nBalances.toString()).equal('0');
    });

    it('usdt 6 decimals', async () => {

      // TODO: should add expect expression
      const price = await integration.priceOf(usdt.address);
      console.log('usdt price: ', price.toString());

      await usdt.mint(investor1, d6(100));
      await usdt.mint(yUSDT.address, d6(100));

      let balance = await usdt.balanceOf(yUSDT.address);
      console.log('current yUSDT USDT balance', balance.toString());

      let pBalances = await integration.balanceOf(usdt.address);
      console.log('current integration usdt balance: ', pBalances.toString());

      await usdt.approve(integration.address, d6(100), {from: investor1});
      const shares = await integration.invest.call(usdt.address, d6(100), {from: investor1});
      console.log('shares of invest usdt: ', shares.toString());

      await integration.invest(usdt.address, d6(100), {from: investor1});
      let nBalances = await integration.balanceOf(usdt.address);
      console.log('current integration usdt balance: ', nBalances.toString());

      balance = await usdt.balanceOf(yUSDT.address);
      console.log('current yUSDT USDT balance', balance.toString());
      await integration.collect(usdt.address, shares, {from: investor1});

      nBalances = await usdt.balanceOf(investor1);
      console.log('current user usdt balance: ', nBalances.toString());

      nBalances = await integration.balanceOf(usdt.address);
      expect(nBalances.toString()).equal('0');
    });

    it('usdt and dai, 6 & 18 decimals', async () => {

      // TODO: should add expect expression

      await dai.mint(investor1, d18(100));
      await usdt.mint(investor1, d6(100));
      await dai.mint(yDAI.address, d18(100));
      await usdt.mint(yUSDT.address, d6(100));

      await dai.approve(integration.address, d18(100), {from: investor1});
      await usdt.approve(integration.address, d6(100), {from: investor1});

      const shares1 = await integration.invest.call(dai.address, d18(100), {from: investor1});
      const shares2 = await integration.invest.call(usdt.address, d6(100), {from: investor1});
      console.log('user shares of invest dai', shares1.toString());
      console.log('user shares of invest usdt', shares2.toString());

      await integration.invest(dai.address, d18(100), {from: investor1});
      await integration.invest(usdt.address, d6(100), {from: investor1});

      let nBalances = await integration.balanceOf(dai.address);
      console.log('current dai balance: ', nBalances.toString());

      nBalances = await integration.balanceOf(usdt.address);
      console.log('current usdt balance: ', nBalances.toString());

      const balances = await integration.balances();
      console.log(balances[2].toString());
      const balance = await integration.totalBalance();
      console.log(balance.toString());
    });
  });
});

