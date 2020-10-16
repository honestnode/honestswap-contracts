import {deployments, ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, utils} from 'ethers';
import {getNamedAccounts, NamedAccounts} from '../scripts/HonestContract.test';

describe('HonestConfiguration', () => {
  let namedAccounts: NamedAccounts;
  let proxyAdmin: Contract, honestAsset: Contract, honestConfiguration: Contract, governorRole: string;
  let dai: Contract, tusd: Contract, usdc: Contract, usdt: Contract;
  let yDAI: Contract, yTUSD: Contract, yUSDC: Contract, yUSDT: Contract;

  const initializeAccounts = async () => {
    namedAccounts = await getNamedAccounts();
  };

  const deployContracts = async () => {
    await deployments.fixture();
    proxyAdmin = await ethers.getContract('DelayedProxyAdmin', namedAccounts.supervisor.signer);
    honestAsset = await ethers.getContract('HonestAsset', namedAccounts.dealer.signer);
    honestConfiguration = await ethers.getContract('HonestConfiguration', namedAccounts.dealer.signer);
    dai = await ethers.getContract('MockDAI', namedAccounts.supervisor.signer);
    tusd = await ethers.getContract('MockTUSD', namedAccounts.supervisor.signer);
    usdc = await ethers.getContract('MockUSDC', namedAccounts.supervisor.signer);
    usdt = await ethers.getContract('MockUSDT', namedAccounts.supervisor.signer);
    yDAI = await ethers.getContract('MockYDAI', namedAccounts.supervisor.signer);
    yTUSD = await ethers.getContract('MockYTUSD', namedAccounts.supervisor.signer);
    yUSDC = await ethers.getContract('MockYUSDC', namedAccounts.supervisor.signer);
    yUSDT = await ethers.getContract('MockYUSDT', namedAccounts.supervisor.signer);
    governorRole = await honestConfiguration.GOVERNOR();
  };

  before(async function () {
    await initializeAccounts();
    await deployContracts();
  });

  describe('HonestAsset', () => {
    it('get initial honest asset', async () => {
      const address = await honestConfiguration.honestAsset();
      expect(address).to.equal(honestAsset.address);
    });

    it('set honest asset of address(0)', async () => {
      await expect(honestConfiguration.setHonestAsset('0x0000000000000000000000000000000000000000')).to.reverted;
    });

    it('set honest asset', async () => {
      await proxyAdmin.grantProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);

      const newContract = await deployments.deploy('NewHonestAsset', {contract: 'HonestAsset', from: namedAccounts.dealer.address});
      expect(newContract.address).not.equal(honestAsset.address);
      await honestConfiguration.setHonestAsset(newContract.address);

      const asset = await honestConfiguration.honestAsset();
      expect(asset).to.equal(newContract.address);

      await proxyAdmin.revokeProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);
    });
  });

  describe('BasketAssets', () => {

    const assertBasketAssets = async (expects: Record<string, boolean>) => {
      const [assets, states]: [string[], boolean[]] = await honestConfiguration.basketAssets();
      expect(assets.length).to.equal(Object.entries(expects).length);
      expect(states.length).to.equal(Object.entries(expects).length);
      Object.entries(expects).forEach(([asset, state], i) => {
        expect(assets[i]).to.equal(asset);
        expect(states[i]).to.equal(state);
      });
      const activeAssets: string[] = await honestConfiguration.activeBasketAssets();
      expect(activeAssets.length).to.equal(Object.entries(expects).filter(([_, state]) => state).length);
      activeAssets.forEach(a => expect(expects[a]).to.equal(true));
    };

    const assertBasketAssetIntegrations = async (assets: Record<string, string>, invalids: string[]) => {
      for (const [asset, investment] of Object.entries(assets)) {
        const investmentIntegration: string = await honestConfiguration.basketAssetInvestmentIntegration(asset);
        expect(investmentIntegration).to.equal(investment);
      }
      for (const asset of invalids) {
        await expect(honestConfiguration.basketAssetInvestmentIntegration(asset)).to.be.reverted;
      }
    };

    it('get initial basket assets', async () => {
      await assertBasketAssets({[dai.address]: true, [tusd.address]: true, [usdc.address]: true, [usdt.address]: true});
      await assertBasketAssetIntegrations({
        [dai.address]: yDAI.address,
        [tusd.address]: yTUSD.address,
        [usdc.address]: yUSDC.address,
        [usdt.address]: yUSDT.address
      }, []);
    });

    it('deactivate basket assets without authorization', async () => {
      await expect(honestConfiguration.deactivateBasketAsset(dai.address)).to.be.reverted;
    });

    it('deactivate basket assets', async () => {
      await proxyAdmin.grantProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);

      await honestConfiguration.deactivateBasketAsset(dai.address);
      await honestConfiguration.deactivateBasketAsset(tusd.address);
      await honestConfiguration.deactivateBasketAsset(usdc.address);
      await assertBasketAssets({
        [dai.address]: false,
        [tusd.address]: false,
        [usdc.address]: false,
        [usdt.address]: true
      });
      await assertBasketAssetIntegrations({
        [usdt.address]: yUSDT.address
      }, [dai.address, tusd.address, usdc.address]);
      await proxyAdmin.revokeProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);
    });

    it('activate basket assets without authorization', async () => {
      await expect(honestConfiguration.activateBasketAsset(dai.address)).to.be.reverted;
    });

    it('activate basket assets', async () => {
      await proxyAdmin.grantProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);
      await honestConfiguration.activateBasketAsset(dai.address);
      await honestConfiguration.activateBasketAsset(usdc.address);
      await assertBasketAssets({
        [dai.address]: true,
        [tusd.address]: false,
        [usdc.address]: true,
        [usdt.address]: true
      });
      await assertBasketAssetIntegrations({
        [dai.address]: yDAI.address,
        [usdc.address]: yUSDC.address,
        [usdt.address]: yUSDT.address
      }, [tusd.address]);
      await proxyAdmin.revokeProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);
    });

    it('remove basket assets without authorization', async () => {
      await expect(honestConfiguration.removeBasketAsset(tusd.address)).to.reverted;
    });

    it('remove basket assets', async () => {
      await proxyAdmin.grantProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);

      await honestConfiguration.removeBasketAsset(tusd.address);
      await honestConfiguration.removeBasketAsset(usdc.address);
      await honestConfiguration.removeBasketAsset(usdt.address);
      await assertBasketAssets({[dai.address]: true});
      await assertBasketAssetIntegrations({
        [dai.address]: yDAI.address
      }, [tusd.address, usdc.address, usdt.address]);
      await proxyAdmin.revokeProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);
    });

    it('add basket assets without authorization', async () => {
      await expect(honestConfiguration.addBasketAsset(tusd.address, yTUSD.address)).to.reverted;
    });

    it('add basket assets', async () => {
      await proxyAdmin.grantProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);
      await honestConfiguration.addBasketAsset(tusd.address, yTUSD.address);
      await honestConfiguration.addBasketAsset(usdc.address, yUSDC.address);
      await honestConfiguration.addBasketAsset(usdt.address, yUSDT.address);
      await assertBasketAssets({[dai.address]: true, [tusd.address]: true, [usdc.address]: true, [usdt.address]: true});
      await assertBasketAssetIntegrations({
        [dai.address]: yDAI.address,
        [tusd.address]: yTUSD.address,
        [usdc.address]: yUSDC.address,
        [usdt.address]: yUSDT.address
      }, []);
      await proxyAdmin.revokeProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);
    });
  });

  describe('FeeRates', () => {
    it('get initial fee rates', async () => {
      const swapFeeRate = await honestConfiguration.swapFeeRate();
      const redeemFeeRate = await honestConfiguration.redeemFeeRate();
      expect(swapFeeRate).to.equal(utils.parseUnits('1', 16));
      expect(redeemFeeRate).to.equal(utils.parseUnits('1', 16));
    });

    it('set fee rates without authorization', async () => {
      await expect(honestConfiguration.setSwapFeeRate(utils.parseUnits('2', 16))).to.reverted;
      await expect(honestConfiguration.setRedeemFeeRate(utils.parseUnits('3', 16))).to.reverted;
    });

    it('set fee rates without authorization', async () => {
      await proxyAdmin.grantProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);

      await honestConfiguration.setSwapFeeRate(utils.parseUnits('4', 16));
      await honestConfiguration.setRedeemFeeRate(utils.parseUnits('5', 16));

      const swapFeeRate = await honestConfiguration.swapFeeRate();
      const redeemFeeRate = await honestConfiguration.redeemFeeRate();
      expect(swapFeeRate).to.equal(utils.parseUnits('4', 16));
      expect(redeemFeeRate).to.equal(utils.parseUnits('5', 16));

      await proxyAdmin.revokeProxyRole(honestConfiguration.address, governorRole, namedAccounts.dealer.address);
    });
  });
});
