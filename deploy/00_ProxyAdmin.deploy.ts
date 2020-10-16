import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {ethers} from 'ethers';
import {deployContract} from '../scripts/HonestContract.deploy';

const deployProxyAdmin: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  await deployContract(bre, 'DelayedProxyAdmin', ethers.BigNumber.from('604800'));
};

export default deployProxyAdmin;