import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {ethers} from 'ethers';
import {deployStandardContract} from '../scripts/HonestContract.deploy';

const deployProxyAdmin: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {
  await deployStandardContract(bre, 'ProxyAdmin');
};

export default deployProxyAdmin;