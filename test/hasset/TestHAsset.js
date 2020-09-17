const BN = require('bn.js');
const {expectRevert} = require('@openzeppelin/test-helpers');
const HAsset = artifacts.require('HAsset');

const MockUSDT = artifacts.require('MockUSDT');
const MockUSDC = artifacts.require('MockUSDC');
const MockTUSD = artifacts.require('MockTUSD');
const MockDAI = artifacts.require('MockDAI');
const BAssetValidatorArtifact = artifacts.require('BAssetValidator');
const MockHonestBasket = artifacts.require('MockHonestBasket');
const MockHonestSaving = artifacts.require('MockHonestSaving');
const MockHonestBonus = artifacts.require('MockHonestBonus');
const MockHonestFee = artifacts.require('MockHonestFee');
const MockBAssetPrice = artifacts.require('MockBAssetPrice');

contract('HAsset', async (accounts) => {

    const fullScale = new BN(10).pow(new BN(18));
    const zero = new BN(0);
    const hundred = new BN(100).mul(fullScale);
    const twoHundred = new BN(200).mul(fullScale);

    const owner = accounts[0];

    let bAssetValidator;
    let hAsset;
    let basket;
    let savings;
    let fee;
    let price;
    let bonus;
    let usdt;
    let usdc;
    let tusd;
    let dai;

    let bAssets;

    const createContract = async () => {
        bAssetValidator = await BAssetValidatorArtifact.new();
        usdt = await MockUSDT.new();
        // usdc = await MockUSDC.new();
        // tusd = await MockTUSD.new();
        // dai = await MockDAI.new();

        // bAssets = [usdt.address, usdc.address, tusd.address, dai.address];
        bAssets = [usdt.address];

        savings = await MockHonestSaving.new();
        bonus = await MockHonestBonus.new();
        fee = await MockHonestFee.new();
        price = await MockBAssetPrice.new();

        basket = await MockHonestBasket.new();

        hAsset = await HAsset.new();
    };

    before(async () => {
        await createContract();
    });

    describe('constructor', async () => {
        it('illegal address', async () => {
            await expectRevert.unspecified(
                //         function initialize(
                //             string calldata _nameArg,
                //         string calldata _symbolArg,
                //         address _nexus,
                //         address _honestBasketInterface,
                //         address _honestSavingsInterface,
                //         address _bAssetPriceInterface,
                //         address _honestBonusInterface,
                //         address _honestFeeInterface,
                //         address _bAssetValidator
                // )
                hAsset.initialize('honest USD', 'hUSD', owner, basket.address, savings.address, price.address, bonus.address, fee.address, bAssetValidator.address)
            );
        });
    });

    describe('mint test', async () => {
        // function mint(address _bAsset, uint256 _bAssetQuantity)
        it('mintTo suc', async () => {
            const mintQuantity = new BN(10).pow(new BN(19));
            const hUSDQuantity = await hAsset.mintTo(usdt.address, mintQuantity);
            console.log("hUSDQuantity=" + hUSDQuantity);
            expect(mintQuantity).equal(hUSDQuantity);
        });
    });

});
