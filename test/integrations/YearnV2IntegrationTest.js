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

  describe('invest', async () => {

    it('invest', async () => {
      await dai.mint(investor1, d18(100));
      await integration.addWhitelisted(investor1);

      const pBalances = await integration.balanceOf(dai.address);

      await dai.approve(integration.address, d18(100), {from: investor1});
      const shares = await integration.invest.call(dai.address, d18(100), {from: investor1});

      expect(shares.toString('hex')).equal(d18(100).toString('hex'));

      await integration.invest(dai.address, d18(100), {from: investor1});
      const nBalances = await integration.balanceOf(dai.address);
      expect(nBalances.sub(pBalances).toString('hex')).equal(d18(100).toString('hex'));
    });

    it('invest', async () => {

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

