import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {deployUpgradableContract, getUpgradableContract} from '../scripts/HonestContract.deploy';

const deployHonestAssetManager: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  const honestConfiguration = await getUpgradableContract('HonestConfiguration');
  const honestVault = await getUpgradableContract('HonestVault');
  await deployUpgradableContract(bre, 'HonestAssetManager', honestConfiguration.address, honestVault.address);
};

export default deployHonestAssetManager;