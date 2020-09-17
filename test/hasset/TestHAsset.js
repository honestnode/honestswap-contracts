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
                //         address _honestBonusInterface,
                //         address _honestFeeInterface,
                //         address _bAssetValidator
                // )
                hAsset.initialize('honest USD', 'hUSD', owner, basket.address, savings.address, bonus.address, fee.address, bAssetValidator.address)
            );
        });
    });

    describe('mint test', async () => {
        // function mintTo(address _bAsset, uint256 _bAssetQuantity, address _recipient) external returns (uint256 hAssetMinted);
        it('mintTo suc', async () => {
            const mintQuantity = new BN(10).pow(new BN(19));
            const hUSDQuantity = await hAsset.mintTo(usdt.address, mintQuantity, owner);
            console.log("hUSDQuantity=" + hUSDQuantity);
            expect(mintQuantity).equal(hUSDQuantity);
        });

        it('mintMultiTo suc', async () => {
            // function mintMultiTo(address[] calldata _bAssets, uint256[] calldata _bAssetQuantity, address _recipient)
            // external returns (uint256 hAssetMinted);
            const mintQuantity = new BN(10).pow(new BN(20));
            const mintBAsset = [usdt.address, usdc.address];
            const mintBAssetQuantities = [mintQuantity, mintQuantity];

            const hUSDQuantity = await hAsset.mintMultiTo(mintBAsset, mintBAssetQuantities, accounts[1]);
            console.log("hUSDQuantity=" + hUSDQuantity);
            expect(true).equal(hUSDQuantity > 0);
        });
    });


    describe('redeem test', async () => {
        it('redeemTo suc', async () => {
            // function redeemTo(address _bAsset, uint256 _bAssetQuantity, address _recipient) external returns (uint256 hAssetRedeemed);
            const quantity = new BN(10).pow(new BN(19));
            const hAssetRedeemed = await hAsset.redeemTo(usdt.address, quantity, owner);
            console.log("hAssetRedeemed=" + hAssetRedeemed);
            expect(true).equal(hAssetRedeemed > 0);
        });

        it('redeemMultiTo suc', async () => {
            // function redeemMultiTo(address[] calldata _bAssets, uint256[] calldata _bAssetQuantities, address _recipient)
            // external returns (uint256 hAssetRedeemed);
            const quantity = new BN(10).pow(new BN(19));
            const redeemBAsset = [usdt.address, usdc.address];
            const redeemBAssetQuantities = [quantity, quantity];

            const hAssetRedeemed = await hAsset.redeemMultiTo(redeemBAsset, redeemBAssetQuantities, accounts[1]);
            console.log("hAssetRedeemed=" + hAssetRedeemed);
            expect(true).equal(hAssetRedeemed > 0);
        });

        it('redeemMultiTo suc', async () => {
            // function redeemMultiInProportionTo(uint256 _bAssetQuantity, address _recipient)
            // external returns (uint256 hAssetRedeemed);
            const quantity = new BN(10).pow(new BN(19));

            const hAssetRedeemed = await hAsset.redeemMultiInProportionTo(quantity, accounts[1]);
            console.log("hAssetRedeemed=" + hAssetRedeemed);
            expect(true).equal(hAssetRedeemed > 0);
        });
    });

});
