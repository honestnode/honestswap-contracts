const BN = require('bn.js');
const {expectRevert} = require('@openzeppelin/test-helpers');
const HonestFee = artifacts.require('HonestFee');
const MockHAsset = artifacts.require('MockHAsset');

contract('HonestFee', async (accounts) => {

  const owner = accounts[0];
  const dummy1 = accounts[1];
  const dummy2 = accounts[2];

  let hAsset;
  let fee;

  const percentage = (number) => {
    return new BN(number).mul(new BN(10).pow(new BN(16)));
  }

  const full = (number) => {
    return new BN(number).mul(new BN(10).pow(new BN(18)));
  };

  const createContract = async () => {
    hAsset = await MockHAsset.new();
    fee = await HonestFee.new(hAsset.address);
  };

  before(async () => {
    await createContract();
  });

  describe('fee rates', async () => {
    it('default fee rate', async () => {
      const swapFeeRate = await fee.swapFeeRate();
      const redeemFeeRate = await fee.redeemFeeRate();
      expect(percentage(1).toString('hex')).equal(swapFeeRate.toString('hex'));
      expect(percentage(1).toString('hex')).equal(redeemFeeRate.toString('hex'));
    });

    it('update fee rate', async () => {
      await fee.setSwapFeeRate(percentage(1.5));
      const swapFeeRate = await fee.swapFeeRate();
      expect(percentage(1.5).toString('hex')).equal(swapFeeRate.toString('hex'));
      await fee.setRedeemFeeRate(percentage(1.4));
      const redeemFeeRate = await fee.redeemFeeRate();
      expect(percentage(1.4).toString('hex')).equal(redeemFeeRate.toString('hex'));
    });

    it('unauthorized update fee rate', async () => {
      await expectRevert.unspecified(
        fee.setSwapFeeRate(percentage(1.5), {from: dummy2})
      );

      await expectRevert.unspecified(
        fee.setRedeemFeeRate(percentage(1.4), {from: dummy2})
      );
    });

    it('grant authorize and update fee rate', async () => {
      await fee.addWhitelistAdmin(dummy2);

      await fee.setSwapFeeRate(percentage(1.6), {from: dummy2});
      expect(percentage(1.6).toString('hex')).equal((await fee.swapFeeRate()).toString('hex'));

      await fee.setRedeemFeeRate(percentage(1.3), {from: dummy2});
      expect(percentage(1.3).toString('hex')).equal((await fee.redeemFeeRate()).toString('hex'));
    });

    it('quite authorize and update fee rate', async () => {
      await fee.renounceWhitelistAdmin({from: dummy2});

      await expectRevert.unspecified(
        fee.setSwapFeeRate(percentage(1.5), {from: dummy2})
      );

      await expectRevert.unspecified(
        fee.setRedeemFeeRate(percentage(1.4), {from: dummy2})
      );
    });
  });

  describe('fees', async () => {
    it('charge fee and totalFees', async () => {

      await hAsset.mint(fee.address, full(100));
      await hAsset.mint(fee.address, full(100));

      expect(full(200).toString('hex')).equal((await fee.totalFee()).toString('hex'));
    });

    it('reward fee', async () => {

      await hAsset.mint(fee.address, full(100));
      const total = await hAsset.balanceOf(fee.address);

      // 20% percentage rewards
      await fee.reward(dummy1, full(20));

      expect(full(20).toString('hex')).equal((await hAsset.balanceOf(dummy1)).toString('hex'));
      expect(full(80).toString('hex')).equal((await hAsset.balanceOf(fee.address)).toString('hex'));
    });
  });
});