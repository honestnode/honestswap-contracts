import {ethers, upgrades} from '@nomiclabs/buidler';
import {Contract} from 'ethers';
import {honestConfigurationDeployer} from './HonestConfiguration.deploy';
import {HonestContractDeployer} from './HonestContract.deploy';

class ChainlinkIntegrationDeployer extends HonestContractDeployer {

  public async deployContracts(): Promise<Contract> {
    const honestConfiguration = await honestConfigurationDeployer.deployContracts();
    const ethPriceFeeds = await this.deploy('MockETH2USDFeeds');
    const ChainlinkIntegration = await ethers.getContractFactory('ChainlinkIntegration');
    return await upgrades.deployProxy(ChainlinkIntegration,
      [honestConfiguration.address, ethPriceFeeds.address],
      {unsafeAllowCustomTypes: true});
  }
}

export const chainlinkIntegrationDeployer = new ChainlinkIntegrationDeployer();