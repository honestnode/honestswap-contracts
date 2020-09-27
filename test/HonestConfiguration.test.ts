import {deployMockContract} from '@ethereum-waffle/mock-contract';
import {ethers, upgrades} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, ContractFactory, Signer} from 'ethers';

import HonestAssetArtifact from '../artifacts/HonestAsset.json';
import {honestAssetDeployer} from '../scripts/HonestAsset.deploy';

describe('HonestConfiguration', () => {
  let supervisor: Signer, honestAsset: Contract, honestConfiguration: Contract, HonestConfiguration: ContractFactory,
    governorRole: string;
  let dai: Contract, tusd: Contract, usdc: Contract, usdt: Contract;
  let yDAI: Contract, yTUSD: Contract, yUSDC: Contract, yUSDT: Contract;
  let daiFeeds: Contract, tusdFeeds: Contract, usdcFeeds: Contract, usdtFeeds: Contract;

  const deployContract = async (name: string, ...args: any[]): Promise<Contract> => {
    const contract: ContractFactory = await ethers.getContractFactory(name);
    return await contract.deploy(...args);
  };

  const deployBasketAssets = async () => {
    dai = await deployContract('MockDAI');
    tusd = await deployContract('MockTUSD');
    usdc = await deployContract('MockUSDC');
    usdt = await deployContract('MockUSDT');
  };

  const deployPriceFeeds = async () => {
    daiFeeds = await deployContract('MockDAI2USDFeeds');
    tusdFeeds = await deployContract('MockTUSD2ETHFeeds');
    usdcFeeds = await deployContract('MockUSDC2ETHFeeds');
    usdtFeeds = await deployContract('MockUSDT2ETHFeeds');
  };

  const deployInvestments = async () => {
    yDAI = await deployContract('MockYDAI', dai.address);
    yTUSD = await deployContract('MockYTUSD', tusd.address);
    yUSDC = await deployContract('MockYUSDC', usdc.address);
    yUSDT = await deployContract('MockYUSDT', usdt.address);
  };

  const deployHonestConfiguration = async () => {
    honestAsset = await honestAssetDeployer.deployContracts();
    await deployBasketAssets();
    await deployPriceFeeds();
    await deployInvestments();
    HonestConfiguration = await ethers.getContractFactory('HonestConfiguration');
    honestConfiguration = await upgrades.deployProxy(HonestConfiguration,
      [honestAsset.address, [dai.address], [0], [daiFeeds.address], [yDAI.address], ethers.utils.parseUnits('1', 16), ethers.utils.parseUnits('2', 16)],
      {unsafeAllowCustomTypes: true});
  };

  before(async function () {
    supervisor = (await ethers.getSigners())[0];
    await deployHonestConfiguration();
    governorRole = await honestConfiguration.GOVERNOR();
  });

  describe('HonestAsset', () => {
    it('get initial honest asset', async () => {
      const address = await honestConfiguration.honestAsset();
      expect(address).to.equal(honestAsset.address);
    });

    it('set honest asset without authorized, revert', async () => {
      const newContract = await deployMockContract(supervisor, HonestAssetArtifact.abi);
      await expect(honestConfiguration.setHonestAsset(newContract.address)).to.reverted;
    });

    it('set honest asset of address(0)', async () => {
      await expect(honestConfiguration.setHonestAsset('0x0000000000000000000000000000000000000000')).to.reverted;
    });

    it('set honest asset', async () => {
      await honestConfiguration.grantRole(governorRole, await supervisor.getAddress());

      const newContract = await deployMockContract(supervisor, HonestAssetArtifact.abi);
      await honestConfiguration.setHonestAsset(newContract.address);

      const asset = await honestConfiguration.honestAsset();
      expect(asset).to.equal(newContract.address);
      await honestConfiguration.revokeRole(governorRole, await supervisor.getAddress());
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

    const assertBasketAssetIntegrations = async (assets: Record<string, {type: number, price: string, investment: string}>, invalids: string[]) => {
      for (const [asset, {type, price, investment}] of Object.entries(assets)) {
        const priceIntegration: [number, string] = await honestConfiguration.basketAssetPriceIntegration(asset);
        expect(priceIntegration[0]).to.equal(type);
        expect(priceIntegration[1]).to.equal(price);
        const investmentIntegration: string = await honestConfiguration.basketAssetInvestmentIntegration(asset);
        expect(investmentIntegration).to.equal(investment);
      }
      for (const asset of invalids) {
        await expect(honestConfiguration.basketAssetPriceIntegration(asset)).to.be.reverted;
        await expect(honestConfiguration.basketAssetInvestmentIntegration(asset)).to.be.reverted;
      }
    };

    it('get initial basket assets', async () => {
      await assertBasketAssets({[dai.address]: true});
      await assertBasketAssetIntegrations({
        [dai.address]: {type: 0, price: daiFeeds.address, investment: yDAI.address}
      }, [tusd.address, usdc.address, usdt.address]);
    });

    it('add basket assets without authorization', async () => {
      await expect(honestConfiguration.addBasketAsset(tusd.address, 1, yTUSD.address, tusdFeeds.address)).to.reverted;
    });

    it('add basket assets', async () => {
      await honestConfiguration.grantRole(governorRole, await supervisor.getAddress());
      await honestConfiguration.addBasketAsset(tusd.address, 1, tusdFeeds.address, yTUSD.address);
      await honestConfiguration.addBasketAsset(usdc.address, 1, usdcFeeds.address, yUSDC.address);
      await honestConfiguration.addBasketAsset(usdt.address, 1, usdtFeeds.address, yUSDT.address);
      await assertBasketAssets({[dai.address]: true, [tusd.address]: true, [usdc.address]: true, [usdt.address]: true});
      await assertBasketAssetIntegrations({
        [dai.address]: {type: 0, price: daiFeeds.address, investment: yDAI.address},
        [tusd.address]: {type: 1, price: tusdFeeds.address, investment: yTUSD.address},
        [usdc.address]: {type: 1, price: usdcFeeds.address, investment: yUSDC.address},
        [usdt.address]: {type: 1, price: usdtFeeds.address, investment: yUSDT.address}
      }, []);
      await honestConfiguration.revokeRole(governorRole, await supervisor.getAddress());
    });

    it('deactivate basket assets without authorization', async () => {
      await expect(honestConfiguration.deactivateBasketAsset(dai.address)).to.be.reverted;
    });

    it('deactivate basket assets', async () => {
      await honestConfiguration.grantRole(governorRole, await supervisor.getAddress());
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
        [usdt.address]: {type: 1, price: usdtFeeds.address, investment: yUSDT.address}
      }, [dai.address, tusd.address, usdc.address]);
      await honestConfiguration.revokeRole(governorRole, await supervisor.getAddress());
    });

    it('activate basket assets without authorization', async () => {
      await expect(honestConfiguration.activateBasketAsset(dai.address)).to.be.reverted;
    });

    it('activate basket assets', async () => {
      await honestConfiguration.grantRole(governorRole, await supervisor.getAddress());
      await honestConfiguration.activateBasketAsset(dai.address);
      await honestConfiguration.activateBasketAsset(usdc.address);
      await assertBasketAssets({
        [dai.address]: true,
        [tusd.address]: false,
        [usdc.address]: true,
        [usdt.address]: true
      });
      await assertBasketAssetIntegrations({
        [dai.address]: {type: 0, price: daiFeeds.address, investment: yDAI.address},
        [usdc.address]: {type: 1, price: usdcFeeds.address, investment: yUSDC.address},
        [usdt.address]: {type: 1, price: usdtFeeds.address, investment: yUSDT.address}
      }, [tusd.address]);
      await honestConfiguration.revokeRole(governorRole, await supervisor.getAddress());
    });

    it('remove basket assets without authorization', async () => {
      await expect(honestConfiguration.removeBasketAsset(tusd.address)).to.reverted;
    });

    it('remove basket assets', async () => {
      await honestConfiguration.grantRole(governorRole, await supervisor.getAddress());

      await honestConfiguration.removeBasketAsset(tusd.address);
      await honestConfiguration.removeBasketAsset(usdc.address);
      await honestConfiguration.removeBasketAsset(usdt.address);
      await assertBasketAssets({[dai.address]: true});
      await assertBasketAssetIntegrations({
        [dai.address]: {type: 0, price: daiFeeds.address, investment: yDAI.address}
      }, [tusd.address, usdc.address, usdt.address]);
      await honestConfiguration.revokeRole(governorRole, await supervisor.getAddress());
    });
  });

  describe('FeeRates', () => {
    it('get initial fee rates', async () => {
      const swapFeeRate = await honestConfiguration.swapFeeRate();
      const redeemFeeRate = await honestConfiguration.redeemFeeRate();
      expect(swapFeeRate).to.equal(ethers.utils.parseUnits('1', 16));
      expect(redeemFeeRate).to.equal(ethers.utils.parseUnits('2', 16));
    });

    it('set fee rates without authorization', async () => {
      await expect(honestConfiguration.setSwapFeeRate(ethers.utils.parseUnits('2', 16))).to.reverted;
      await expect(honestConfiguration.setRedeemFeeRate(ethers.utils.parseUnits('3', 16))).to.reverted;
    });

    it('set fee rates without authorization', async () => {
      await honestConfiguration.grantRole(governorRole, await supervisor.getAddress());

      await honestConfiguration.setSwapFeeRate(ethers.utils.parseUnits('4', 16));
      await honestConfiguration.setRedeemFeeRate(ethers.utils.parseUnits('5', 16));

      const swapFeeRate = await honestConfiguration.swapFeeRate();
      const redeemFeeRate = await honestConfiguration.redeemFeeRate();
      expect(swapFeeRate).to.equal(ethers.utils.parseUnits('4', 16));
      expect(redeemFeeRate).to.equal(ethers.utils.parseUnits('5', 16));

      await honestConfiguration.revokeRole(governorRole, await supervisor.getAddress());
    });
  });
});
