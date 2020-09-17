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
    const investor1 = accounts[1];
    const investor2 = accounts[2];

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
        it('getBalance suc', async () => {
            const usdtBalance = await basket.getBalance(usdt.address);
            console.log("usdtBalance=" + usdtBalance);
            expect(true).equal(usdtBalance > 0);
        });

        it('getBAssetsBalance failed', async () => {
            const array = await basket.getBAssetsBalance(bAssets);
            console.log("array=" + array + ", sum=" + array[0] + ", other=" + array[1]);
            expect(true).equal(array[0] > 0);
        });
    });

    describe('constructor', async () => {
        it('illegal address', async () => {
            await expectRevert.unspecified(
                basket.initialize(owner, hAsset.address, bAssets, savings.address, fee.address, bAssetValidator.address)
            )
            ;
        });
    });

});
