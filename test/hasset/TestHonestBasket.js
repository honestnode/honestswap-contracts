const BN = require('bn.js');
const {expectRevert} = require('@openzeppelin/test-helpers');
const MockUSDT = artifacts.require('MockUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockTUSD = artifacts.require('MockTUSD');
const MockDAI = artifacts.require('MockDAI');
const BAssetValidatorArtifact = artifacts.require('BAssetValidator');
const MockHAsset = artifacts.require('MockHAsset');
const HonestBasket = artifacts.require('HonestBasket');
const MockHonestSaving = artifacts.require('MockHonestSaving');
const MockHonestFee = artifacts.require('MockHonestFee');


contract('HonestBasket', async (accounts) => {

    const fullScale = new BN(10).pow(new BN(18));
    const zero = new BN(0);
    const hundred = new BN(100).mul(fullScale);
    const twoHundred = new BN(200).mul(fullScale);

    const feeRate = new BN(10).pow(new BN(15));

    const owner = accounts[0];
    // const investor1 = accounts[1];
    // const investor2 = accounts[2];

    let bAssetValidator;
    let hAsset;
    let basket;
    let savings;
    let fee;
    let usdt;
    let usdc;
    let tusd;
    let dai;

    let bAssets;

    const createContract = async () => {
        bAssetValidator = await BAssetValidatorArtifact.new();
        usdt = await MockUSDT.new();
        usdc = await MockUSDC.new();
        tusd = await MockTUSD.new();
        dai = await MockDAI.new();

        hAsset = await MockHAsset.new();
        savings = await MockHonestSaving.new();
        fee = await MockHonestFee.new();
        basket = await HonestBasket.new();

        bAssets = [usdt.address, usdc.address, tusd.address, dai.address];
    };

    before(async () => {
        await createContract();
        await fee.setSwapFeeRate(feeRate);
        await fee.setRedeemFeeRate(feeRate);
        const swapFeeRate = await fee.swapFeeRate();
        console.log("swapFeeRate=" + swapFeeRate);
        const redeemFeeRate = await fee.redeemFeeRate();
        console.log("redeemFeeRate=" + redeemFeeRate);


    });

    describe('constructor', async () => {
        it('illegal address', async () => {
            await expectRevert.unspecified(
                basket.initialize(owner, hAsset.address, bAssets, savings.address, fee.address, bAssetValidator.address)
            )
            ;
        });
    });

    describe('query balance', async () => {
        // function validateMint(address _bAsset, uint8 _bAssetStatus, uint256 _bAssetQuantity)
        // it('getBalance suc', async () => {
        //     const usdtBalance = await basket.getBalance(usdt.address);
        //     console.log("usdtBalance=" + usdtBalance);
        //     expect(true).equal(usdtBalance > 0);
        // });

        it('getBAssetsBalance suc', async () => {
            const array = await basket.getBAssetsBalance(bAssets);
            console.log("array=" + array + ", array[0]=" + array[0] + ", array[1]=" + array[1]);
            expect(true).equal(array[0] > 0);
        });

        it('getBasketAllBalance suc', async () => {
            const array = await basket.getBasketAllBalance();
            console.log("array=" + array + ", array[0]=" + array[0] + ", array[1]=" + array[1]);
            expect(true).equal(array[0] > 0);
        });
    });

    describe('get Basket info', async () => {
        it('getBasket()', async () => {
            const array = await basket.getBasket();
            console.log("array=" + array + ", array[0]=" + array[0] + ", array[1]=" + array[1]);
            expect(usdt.address).equal(array[0]);
        });

        it('getBAssetStatus suc', async () => {
            const array = await basket.getBAssetStatus(usdt.address);
            console.log("array=" + array + ", array[0]=" + array[0] + ", array[1]=" + array[1]);
            expect(true).equal(array[0]);
        });

        it('getBAssetsStatus suc', async () => {
            const array = await basket.getBAssetsStatus(bAssets);
            console.log("array=" + array + ", array[0]=" + array[0] + ", array[1]=" + array[1]);
            expect(true).equal(array[0]);
        });

        it('addBAsset suc', async () => {
            // function addBAsset(address _bAsset, uint8 _status) external returns (uint8 index);
            const index = await basket.addBAsset(dai.address, 0);
            console.log("index=" + index);
            expect(true).equal(index >= 0);
        });

        it('updateBAssetStatus suc', async () => {
            // function updateBAssetStatus(address _bAsset, uint8 _newStatus) external returns (uint8 index);
            const index = await basket.updateBAssetStatus(dai.address, 1);
            console.log("index=" + index);
            expect(true).equal(index >= 0);
        });


    });

    describe('user swap', async () => {
        it('getSwapOutput suc', async () => {
            // function getSwapOutput(address _input, address _output, uint256 _quantity)
            // external returns (bool, string memory, uint256 outputQuantity);
            const array = await basket.getSwapOutput(usdt.address, usdc.address, 10);
            console.log("array=" + array + ", array[0]=" + array[0] + ", array[1]=" + array[1]);
            expect(true).equal(array[0]);
        });

        it('swap suc', async () => {
            // function swap(address _input, address _output, uint256 _quantity, address _recipient)
            // external returns (uint256 outputQuantity);
            const outputQuantity = await basket.swap(usdt.address, usdc.address, 10, accounts[1]);
            console.log("outputQuantity=" + outputQuantity);
            expect(true).equal(outputQuantity > 0);
        });

    });

});
