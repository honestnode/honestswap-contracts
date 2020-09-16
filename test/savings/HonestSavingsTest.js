const BN = require('bn.js');
const {expectRevert} = require('@openzeppelin/test-helpers');
const MockHAsset = artifacts.require('MockHAsset');
const MockHonestBasket = artifacts.require('MockHonestBasket');
const MockHonestFee = artifacts.require('MockHonestFee');
const MockHonestBonus = artifacts.require('MockHonestBonus');
const HonestSavings = artifacts.require('HonestSavings');
const YearnV2Integration = artifacts.require('YearnV2Integration');
const MockDAI = artifacts.require('MockDAI');
const MockUSDT = artifacts.require('MockUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockTUSD = artifacts.require('MockTUSD');

/*
    function deposit(uint256 _amount) external returns (uint256);

    function withdraw(uint256 _shares) external returns (uint256);

    function savingsOf(address _account) external view returns (uint256);

    function sharesOf(address _account) external view returns (uint256);

    function totalSavings() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function sharePrice() external view returns (uint256);

    function apy() external view returns (uint256);

    function swap(address _account, address[] calldata _bAssets, uint256[] calldata _borrows, address[] calldata _sAssets, uint256[] calldata _supplies)
    external;

    function investments() external view returns (address[] memory, uint256[] memory _amounts);

    function investmentOf(address[] calldata _bAssets) external view returns (uint256[] memory);
 */

contract('HonestSavings', async (accounts) => {

  const fullScale = new BN(10).pow(new BN(18));
  const zero = new BN(0);
  const hundred = new BN(100).mul(fullScale);
  const twoHundred = new BN(200).mul(fullScale);

  const shift = (value, offset = 18) => {
    if (offset === 0) {
      return new BN(value);
    } else if (offset > 0) {
      return new BN(value).mul(new BN(10).pow(new BN(offset)));
    } else {
      return new BN(value).div(new BN(10).pow(new BN(offset)));
    }
  }

  const owner = accounts[0];
  const investor1 = accounts[1];
  const investor2 = accounts[2];

  let hAsset, basket, savings, yearn, fee, bonus, dai, tusd, usdc, usdt;

  const createContract = async () => {
    dai = await MockDAI.deployed();
    tusd = await MockTUSD.deployed();
    usdc = await MockUSDC.deployed();
    usdt = await MockUSDT.deployed();
    hAsset = await MockHAsset.new();
    basket = await MockHonestBasket.new();
    await basket.initialize(hAsset.address);
    await hAsset.mint(basket.address, shift(1000));
    await hAsset.mint(investor1, shift(100));
    await hAsset.mint(investor2, shift(100));

    await dai.mint(basket.address, shift(1000));
    await tusd.mint(basket.address, shift(1000));
    await usdc.mint(basket.address, shift(1000));
    await usdt.mint(basket.address, shift(1000));
    yearn = await YearnV2Integration.deployed();
    fee = await MockHonestFee.new();
    await fee.initialize(hAsset.address);
    bonus = await MockHonestBonus.new();
    savings = await HonestSavings.new();
    await yearn.addWhitelisted(savings.address);
    await savings.initialize(hAsset.address, basket.address, yearn.address, fee.address, bonus.address);
  };

  before(async () => {
    await createContract();
  });

  // describe('deposit', async () => {
  //
  //   it('deposit zero', async () => {
  //     await expectRevert.unspecified( // zero amount
  //       savings.deposit(zero, {from: investor1})
  //     );
  //   });
  //
  //   it('insufficient balance', async () => {
  //     await hAsset.mint(investor2, hundred);
  //     await hAsset.approve(savings.address, twoHundred, {from: investor2});
  //     await expectRevert.unspecified( // insufficient balance
  //       savings.deposit(twoHundred, {from: investor2})
  //     );
  //   });
  //
  //   it('no approve', async () => {
  //     await hAsset.mint(investor1, hundred);
  //     await expectRevert.unspecified( // no approve
  //       savings.deposit(hundred, {from: investor1})
  //     );
  //   });
  // });

  describe('deposit and withdraw', async () => {

    const printStatement = async (investor) => {
      const balance = await hAsset.balanceOf(investor);
      const shares = await savings.sharesOf(investor);
      const saving = await savings.savingsOf(investor);
      const totalShares = await savings.totalShares();
      console.log('------ statements');
      console.log('investor hAsset balance: ', balance.toString());
      console.log('investor savings: ', saving.toString());
      console.log('investor share: ', shares.toString());
      console.log('total shares: ', totalShares.toString());
      console.log('------');
    };

    const deposit100 = async (investor) => {
      console.log('== deposit ==');
      await printStatement(investor);
      await hAsset.approve(savings.address, shift(100), {from: investor});

      const shares = await savings.deposit.call(shift(100), {from: investor});
      await savings.deposit(shift(100), {from: investor});
      console.log('deposit shares: ', shares.toString());

      await printStatement(investor);
      return shares;
    };

    const withdraw100 = async (investor) => {
      console.log('== withdraw ==');
      const saving = await savings.savingsOf(investor);
      await printStatement(investor);

      await savings.withdraw(saving, {from: investor});

      await printStatement(investor);
    };
    //
    // it('deposit and withdraw without fee and bonus', async () => {
    //   await deposit100(investor1);
    // });

    it('deposit and withdraw without bonus', async () => {
      // assume the fee have 200 hAssets
      hAsset.mint(fee.address, shift(200));
      await deposit100(investor1);
      await deposit100(investor2);
      await withdraw100(investor1);
      await withdraw100(investor2);
    });
  });
});