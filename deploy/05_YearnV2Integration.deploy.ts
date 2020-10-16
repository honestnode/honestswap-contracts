import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {deployUpgradableContract} from '../scripts/HonestContract.deploy';

const deployYearnV2Integration: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  const honestConfiguration = await bre.deployments.get('HonestConfiguration');
  await deployUpgradableContract(bre, 'YearnV2Integration', honestConfiguration.address);
};

export default deployYearnV2Integration;