import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {deployUpgradableContract} from '../scripts/HonestContract.deploy';

const deployHonestAssetManager: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  const honestConfiguration = await bre.deployments.get('HonestConfiguration');
  const honestVault = await bre.deployments.get('HonestVault');
  await deployUpgradableContract(bre, 'HonestAssetManager', honestConfiguration.address, honestVault.address);
};

export default deployHonestAssetManager;