import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {deployUpgradableContract} from '../scripts/HonestContract.deploy';

const deployHonestVault: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  const honestConfiguration = await bre.deployments.get('HonestConfiguration');
  const investment = await bre.deployments.get('YearnV2Integration');
  const honestFee = await bre.deployments.get('HonestFee');
  await deployUpgradableContract(bre, 'HonestVault', honestConfiguration.address, investment.address, honestFee.address);
};

export default deployHonestVault;