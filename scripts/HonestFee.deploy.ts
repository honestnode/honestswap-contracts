import {Contract} from 'ethers';
import {HonestContractDeployer} from './HonestContract.deploy';

class HonestFeeDeployer extends HonestContractDeployer {

  public async deployContracts(honestConfiguration: Contract): Promise<Contract> {
    return this.deployUpgradable('HonestFee', honestConfiguration.address);
  }
}

export const honestFeeDeployer = new HonestFeeDeployer();