import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {deployUpgradableContract, getUpgradableContract} from '../scripts/HonestContract.deploy';

const deployHonestBonus: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  const honestConfiguration = await getUpgradableContract('HonestConfiguration');
  const honestVault = await getUpgradableContract('HonestVault');
  await deployUpgradableContract(bre, 'HonestBonus', honestConfiguration.address, honestVault.address);
};

export default deployHonestBonus;