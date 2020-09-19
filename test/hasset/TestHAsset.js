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

    const shift = (value, offset = 18) => {
        if (offset === 0) {
            return new BN(value);
        } else if (offset > 0) {
            return new BN(value).mul(new BN(10).pow(new BN(offset)));
        } else {
            return new BN(value).div(new BN(10).pow(new BN(offset)));
        }
    }

    const createContract = async () => {
        bAssetValidator = await BAssetValidatorArtifact.new();
        usdt = await MockUSDT.new();
        usdc = await MockUSDC.new();
        // tusd = await MockTUSD.new();
        // dai = await MockDAI.new();

        // bAssets = [usdt.address, usdc.address, tusd.address, dai.address];
        bAssets = [usdt.address, usdc.address];

        savings = await MockHonestSaving.new();
        bonus = await MockHonestBonus.new();
        fee = await MockHonestFee.new();

        basket = await MockHonestBasket.new();

        hAsset = await HAsset.new();

        hAsset.initialize('honest USD', 'hUSD', owner, basket.address, savings.address, bonus.address, fee.address, bAssetValidator.address)
    };

    before(async () => {
        await createContract();
    });

    describe('mint test', async () => {
        // function mintTo(address _bAsset, uint256 _bAssetQuantity, address _recipient) external returns (uint256 hAssetMinted);
        it('mintTo suc', async () => {
            const mintQuantity = shift(100);
            const hUSDQuantity = await hAsset.mintTo(usdt.address, mintQuantity, owner);
            console.log("hUSDQuantity=" + hUSDQuantity);
            expect(mintQuantity).equal(hUSDQuantity);
        });

        it('mintMultiTo suc', async () => {
            // function mintMultiTo(address[] calldata _bAssets, uint256[] calldata _bAssetQuantity, address _recipient)
            // external returns (uint256 hAssetMinted);
            const mintQuantity = shift(200);
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
            const quantity = shift(10);
            const hAssetRedeemed = await hAsset.redeemTo(usdt.address, quantity, owner);
            console.log("hAssetRedeemed=" + hAssetRedeemed);
            expect(true).equal(hAssetRedeemed > 0);
        });

        it('redeemMultiTo suc', async () => {
            // function redeemMultiTo(address[] calldata _bAssets, uint256[] calldata _bAssetQuantities, address _recipient)
            // external returns (uint256 hAssetRedeemed);
            const quantity = shift(20);
            const redeemBAsset = [usdt.address, usdc.address];
            const redeemBAssetQuantities = [quantity, quantity];

            const hAssetRedeemed = await hAsset.redeemMultiTo(redeemBAsset, redeemBAssetQuantities, accounts[1]);
            console.log("hAssetRedeemed=" + hAssetRedeemed);
            expect(true).equal(hAssetRedeemed > 0);
        });

        it('redeemMultiTo suc', async () => {
            // function redeemMultiInProportionTo(uint256 _bAssetQuantity, address _recipient)
            // external returns (uint256 hAssetRedeemed);
            const quantity = shift(10);

            const hAssetRedeemed = await hAsset.redeemMultiInProportionTo(quantity, accounts[1]);
            console.log("hAssetRedeemed=" + hAssetRedeemed);
            expect(true).equal(hAssetRedeemed > 0);
        });
    });

});
