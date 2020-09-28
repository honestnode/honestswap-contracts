import {Contract} from 'ethers';
import {HonestContractDeployer} from '../HonestContract.deploy';

class YearnV2IntegrationDeployer extends HonestContractDeployer {

  public async deployContracts(honestConfiguration: Contract): Promise<Contract> {
    return this.deployUpgradable('YearnV2Integration', honestConfiguration.address);
  }
}

export const yearnV2IntegrationDeployer = new YearnV2IntegrationDeployer();