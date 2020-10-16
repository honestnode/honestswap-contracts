import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {ethers} from 'ethers';
import {deployStandardContract} from '../scripts/HonestContract.deploy';

const deployTimelock: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  const {supervisor} = await bre.getNamedAccounts();
  const delay: ethers.BigNumber = ethers.BigNumber.from('604800');
  await deployStandardContract(bre, 'Timelock', supervisor, delay);
};

export default deployTimelock;