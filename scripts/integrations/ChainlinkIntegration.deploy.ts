import {Contract} from 'ethers';
import {HonestContractDeployer} from '../HonestContract.deploy';

class ChainlinkIntegrationDeployer extends HonestContractDeployer {

  public async deployContracts(honestConfiguration: Contract): Promise<Contract> {
    const ethPriceFeeds = await this.deploy('MockETH2USDFeeds');
    return this.deployUpgradable('ChainlinkIntegration', honestConfiguration.address, ethPriceFeeds.address);
  }
}

export const chainlinkIntegrationDeployer = new ChainlinkIntegrationDeployer();