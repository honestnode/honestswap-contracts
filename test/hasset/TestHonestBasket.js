const BN = require('bn.js');
const {expectRevert} = require('@openzeppelin/test-helpers');
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

    let hAsset;
    let basket;
    let savings;
    let fee;

    const createContract = async () => {
        hAsset = await MockHAsset.new();
        savings = await MockHonestSaving.new();
        fee = await MockHonestFee.new();
        basket = await HonestBasket.new();
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
                HonestSavings.new('0x0000000000000000000000000000000000000000')
            );
        });
    });

    describe('deposit', async () => {

        it('deposit zero', async () => {
            await expectRevert.unspecified( // zero amount
                savings.deposit(zero, {from: investor1})
            );
        });

        it('insufficient balance', async () => {
            await hAsset.mint(investor2, hundred);
            await hAsset.approve(savings.address, twoHundred, {from: investor2});
            await expectRevert.unspecified( // insufficient balance
                savings.deposit(twoHundred, {from: investor2})
            );
        });

        it('no approve', async () => {
            await hAsset.mint(investor1, hundred);
            await expectRevert.unspecified( // no approve
                savings.deposit(hundred, {from: investor1})
            );
        });

        it('deposit and withdraw', async () => {
            const balance = await hAsset.balanceOf(investor1);
            await hAsset.mint(investor1, hundred);
            await hAsset.approve(savings.address, hundred, {from: investor1});

            await savings.deposit(hundred, {from: investor1});

            expect(hundred.toString('hex')).equal((await savings.savingsOf(investor1)).toString('hex'));
            expect(balance.add(zero).toString('hex')).equal((await hAsset.balanceOf(investor1)).toString('hex'));

            await savings.withdraw(hundred, {from: investor1});

            expect(zero.toString('hex')).equal((await savings.savingsOf(investor1)).toString('hex'));
            expect(balance.add(hundred).toString('hex')).equal((await hAsset.balanceOf(investor1)).toString('hex'));
        });
    });
});
