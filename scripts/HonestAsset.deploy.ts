import {Contract} from 'ethers';
import {HonestContractDeployer} from './HonestContract.deploy';

class HonestAssetDeployer extends HonestContractDeployer {

  public async deployContracts(): Promise<Contract> {
    return this.deployUpgradable('HonestAsset', 'Honest USD', 'hUSD');
  }
}

export const honestAssetDeployer = new HonestAssetDeployer();