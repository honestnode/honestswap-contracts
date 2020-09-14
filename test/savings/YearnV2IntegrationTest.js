const BN = require('bn.js');
const MockDAI = artifacts.require('MockDAI');
const MockYDAI = artifacts.require('MockYDAI');
const MockUSDT = artifacts.require('MockUSDT');
const MockYUSDT = artifacts.require('MockYUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockYUSDC = artifacts.require('MockYUSDC');
const MockTUSD = artifacts.require('MockTUSD');
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
    dai = await MockDAI.new();
    tusd = await MockTUSD.new();
    usdc = await MockUSDC.new();
    usdt = await MockUSDT.new();
    yDAI = await MockYDAI.new(dai.address);
    yTUSD = await MockYTUSD.new(tusd.address);
    yUSDC = await MockYUSDC.new(usdc.address);
    yUSDT = await MockYUSDT.new(usdt.address);
    integration = await YearnV2Integration.new();
  };

  before(async () => {
    await createContract();
  });

  describe('assets', async () => {

    it('add/remove assets', async () => {
      await integration.addAsset(dai.address, yDAI.address);
      await integration.addAsset(tusd.address, yTUSD.address);
      let assets = await integration.assets();
      expect(assets.length).equal(2);

      await integration.removeAsset(dai.address);
      assets = await integration.assets();
      expect(assets.length).equal(1);

      await integration.removeAsset(tusd.address);
      assets = await integration.assets();
      expect(assets.length).equal(0);

      await integration.addAsset(dai.address, yDAI.address);
      await integration.addAsset(tusd.address, yTUSD.address);
      await integration.addAsset(usdc.address, yUSDC.address);
      await integration.addAsset(usdt.address, yUSDT.address);
      assets = await integration.assets();
      expect(assets.length).equal(4);
    });

    it ('duplicated add asset', async () => {
      const oAssets = await integration.assets();

      await integration.addAsset(dai.address, yDAI.address);

      const nAssets = await integration.assets();
      expect(nAssets.length).equal(oAssets.length);
    });


  });

  describe('invest', async () => {

    it('invest', async () => {
      await dai.mint(investor1, d18(100));
      await integration.addWhitelisted(investor1);

      const pBalances = await integration.balanceOf(dai.address);

      await dai.approve(integration.address, d18(100), {from: investor1});
      const shares = await integration.invest.call(dai.address, d18(100), {from: investor1});

      expect(shares.toString('hex')).equal(d18(100).toString('hex'));

      const nBalances = await integration.balanceOf(dai.address);
      expect(nBalances.sub(pBalances).toString('hex')).equal(d18(100).toString('hex'));
    });
  });
});

/*
    function assets() external view returns (address[] memory);

    function addAsset(address _address, address _yAddress) external;

    function removeAsset(address _address, address _yAddress) external;

    function invest(address _asset, uint256 _amount) external returns (uint256);

    function collect(address _bAsset, uint256 _shares) external returns (uint256);

    function valueOf(address _bAsset) external view returns (uint256);

    function balanceOf(address _bAsset) external view returns (uint256);

    function balances() external view returns (address[] memory, uint256[] memory, uint256);

    function totalBalance() external view returns (uint256);
 */

