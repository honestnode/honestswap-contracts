import {Contract} from 'ethers';
import {HonestContractDeployer} from './HonestContract.deploy';

class HonestVaultDeployer extends HonestContractDeployer {

  public async deployContracts(honestConfiguration: Contract, investmentIntegration: Contract, honestFee: Contract): Promise<Contract> {
    return this.deployUpgradable('HonestVault', honestConfiguration.address, investmentIntegration.address, honestFee.address);
  }
}

export const honestVaultDeployer = new HonestVaultDeployer();