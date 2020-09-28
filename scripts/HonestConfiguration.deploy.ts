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
      [honestAsset.address, basketAssets.map(c => c.address), prices.map(p => p.target), prices.map(p => p.feeds), investments, ethers.utils.parseUnits('1', 16), ethers.utils.parseUnits('1', 16)],
      {unsafeAllowCustomTypes: true});
  }

  public async deployBasketAssets(): Promise<Contract[]> {
    const dai = await this.deploy('MockDAI');
    const tusd = await this.deploy('MockTUSD');
    const usdc = await this.deploy('MockUSDC');
    const usdt = await this.deploy('MockUSDT');
    return [dai, tusd, usdc, usdt];
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

  public async deployInvestments(bAssets: Contract[]): Promise<string[]> {
    const yDAI = await this.deploy('MockYDAI', bAssets[0].address);
    const yTUSD = await this.deploy('MockYTUSD', bAssets[1].address);
    const yUSDC = await this.deploy('MockYUSDC', bAssets[2].address);
    const yUSDT = await this.deploy('MockYUSDT', bAssets[3].address);
    await bAssets[0].mint(yDAI.address, ethers.utils.parseUnits('1000', 18));
    await bAssets[1].mint(yTUSD.address, ethers.utils.parseUnits('1000', 18));
    await bAssets[2].mint(yUSDC.address, ethers.utils.parseUnits('1000', 6));
    await bAssets[3].mint(yUSDT.address, ethers.utils.parseUnits('1000', 6));
    return [yDAI.address, yTUSD.address, yUSDC.address, yUSDT.address];
  }
}

export const honestConfigurationDeployer = new HonestConfigurationDeployer();