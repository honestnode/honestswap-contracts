const BN = require('bn.js');
const {expectRevert} = require('@openzeppelin/test-helpers');
const HAsset = artifacts.require('HAsset');
const HonestBasket = artifacts.require('HonestBasket');

contract('HAsset', async (accounts) => {

    // const fullScale = new BN(10).pow(new BN(18));
    // const zero = new BN(0);
    // const hundred = new BN(100).mul(fullScale);
    // const twoHundred = new BN(200).mul(fullScale);

    const owner = accounts[0];

    let hAsset;
    let honestBasket;

    const createContract = async () => {
        hAsset = await HAsset.new();
        honestBasket = await HonestBasket.new();
    };

    before(async () => {
        await createContract();
    });

    describe('constructor', async () => {
        it('illegal address', async () => {
            await expectRevert.unspecified(

            );
        });
    });

    // describe('deposit', async () => {
    //
    //     it('deposit zero', async () => {
    //         await expectRevert.unspecified( // zero amount
    //             savings.deposit(zero, {from: investor1})
    //         );
    //     });
    //
    //     it('insufficient balance', async () => {
    //         await hAsset.mint(investor2, hundred);
    //         await hAsset.approve(savings.address, twoHundred, {from: investor2});
    //         await expectRevert.unspecified( // insufficient balance
    //             savings.deposit(twoHundred, {from: investor2})
    //         );
    //     });
    //
    //     it('no approve', async () => {
    //         await hAsset.mint(investor1, hundred);
    //         await expectRevert.unspecified( // no approve
    //             savings.deposit(hundred, {from: investor1})
    //         );
    //     });
    //
    //     it('deposit and withdraw', async () => {
    //         const balance = await hAsset.balanceOf(investor1);
    //         await hAsset.mint(investor1, hundred);
    //         await hAsset.approve(savings.address, hundred, {from: investor1});
    //
    //         await savings.deposit(hundred, {from: investor1});
    //
    //         expect(hundred.toString('hex')).equal((await savings.savingsOf(investor1)).toString('hex'));
    //         expect(balance.add(zero).toString('hex')).equal((await hAsset.balanceOf(investor1)).toString('hex'));
    //
    //         await savings.withdraw(hundred, {from: investor1});
    //
    //         expect(zero.toString('hex')).equal((await savings.savingsOf(investor1)).toString('hex'));
    //         expect(balance.add(hundred).toString('hex')).equal((await hAsset.balanceOf(investor1)).toString('hex'));
    //     });
    // });
});
