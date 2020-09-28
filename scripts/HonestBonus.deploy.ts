import {Contract} from 'ethers';
import {HonestContractDeployer} from './HonestContract.deploy';

class HonestBonusDeployer extends HonestContractDeployer {

  public async deployContracts(priceIntegration: Contract): Promise<Contract> {
    return this.deployUpgradable('HonestBonus', priceIntegration.address);
  }
}

export const honestBonusDeployer = new HonestBonusDeployer();