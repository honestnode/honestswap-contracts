import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {deployUpgradableContract, getUpgradableContract} from '../scripts/HonestContract.deploy';

const deployHonestFee: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  const honestConfiguration = await getUpgradableContract('HonestConfiguration');
  await deployUpgradableContract(bre, 'HonestFee', honestConfiguration.address);
};

export default deployHonestFee;