import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {deployUpgradableContract} from '../scripts/HonestContract.deploy';

const deployHonestAsset: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  await deployUpgradableContract(bre, 'HonestAsset', 'Honest Asset', 'hUSD');
};

export default deployHonestAsset;