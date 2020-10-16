import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {ethers} from 'ethers';
import {deployUpgradableContract} from '../scripts/HonestContract.deploy';

const deployHonestFee: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  const honestConfiguration = await bre.deployments.get('HonestConfiguration');
  await deployUpgradableContract(bre, 'HonestFee', honestConfiguration.address, ethers.utils.parseUnits('8', 17));
};

export default deployHonestFee;