import {ethers, upgrades} from '@nomiclabs/buidler';
import {Contract} from 'ethers';
import {honestAssetDeployer} from './HonestAsset.deploy';
import {HonestContractDeployer} from './HonestContract.deploy';

export class HonestConfigurationDeployer extends HonestContractDeployer {

  public async deployContracts(): Promise<Contract> {
    const honestAsset = await honestAssetDeployer.deployContracts();
    const basketAssets = await this.deployBasketAssets();
    const prices = await this.deployPriceFeeds();
    const investments = await this.deployInvestments(basketAssets);
    const HonestConfiguration = await ethers.getContractFactory('HonestConfiguration');
    return await upgrades.deployProxy(HonestConfiguration,
      [honestAsset.address, basketAssets, prices.map(p => p.target), prices.map(p => p.feeds), investments, ethers.utils.parseUnits('1', 16), ethers.utils.parseUnits('1', 16)],
      {unsafeAllowCustomTypes: true});
  }

  public async deployBasketAssets(): Promise<string[]> {
    const dai = await this.deploy('MockDAI');
    const tusd = await this.deploy('MockTUSD');
    const usdc = await this.deploy('MockUSDC');
    const usdt = await this.deploy('MockUSDT');
    return [dai.address, tusd.address, usdc.address, usdt.address];
  }

  public async deployPriceFeeds(): Promise<{target: number, feeds: string}[]> {
    const daiFeeds = await this.deploy('MockDAI2USDFeeds');
    const tusdFeeds = await this.deploy('MockTUSD2ETHFeeds');
    const usdcFeeds = await this.deploy('MockUSDC2ETHFeeds');
    const usdtFeeds = await this.deploy('MockUSDT2ETHFeeds');
    return [
      {target: 0, feeds: daiFeeds.address},
      {target: 1, feeds: tusdFeeds.address},
      {target: 1, feeds: usdcFeeds.address},
      {target: 1, feeds: usdtFeeds.address}
    ];
  }

  public async deployInvestments(bAssets: string[]): Promise<string[]> {
    const yDAI = await this.deploy('MockYDAI', bAssets[0]);
    const yTUSD = await this.deploy('MockYTUSD', bAssets[1]);
    const yUSDC = await this.deploy('MockYUSDC', bAssets[2]);
    const yUSDT = await this.deploy('MockYUSDT', bAssets[3]);
    return [yDAI.address, yTUSD.address, yUSDC.address, yUSDT.address];
  }
}

export const honestConfigurationDeployer = new HonestConfigurationDeployer();