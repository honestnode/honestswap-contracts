import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {deployUpgradableContract, getUpgradableContract} from '../scripts/HonestContract.deploy';

const deployHonestVault: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  const honestConfiguration = await getUpgradableContract('HonestConfiguration');
  const investment = await getUpgradableContract('YearnV2Integration');
  const honestFee = await getUpgradableContract('HonestFee');
  await deployUpgradableContract(bre, 'HonestVault', honestConfiguration.address, investment.address, honestFee.address);
};

export default deployHonestVault;