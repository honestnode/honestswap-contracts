import { ethers } from '@nomiclabs/buidler';
import {ABI, BuidlerRuntimeEnvironment, Deployment} from '@nomiclabs/buidler/types';
import {Signer, utils} from 'ethers';

export const deployContract = async (bre: BuidlerRuntimeEnvironment, name: string, contractName: string, ...args: any[]): Promise<Deployment> => {
  const {deployments, getNamedAccounts} = bre;
  const {deploy} = deployments;
  const {supervisor} = await getNamedAccounts();

  return await deploy(name, {
    contract: contractName,
    from: supervisor,
    log: true,
    args: args
  });
};

export const deployUpgradableContract = async (bre: BuidlerRuntimeEnvironment, contractName: string, ...args: any[]): Promise<string> => {
  const {deployments} = bre;
  const {log, get} = deployments;

  log(`--- ${contractName}`);

  const proxyAdmin = await get('ProxyAdmin');
  const implementation = await deployContract(bre, `${contractName}Implementation`, contractName);
  const data: string = new utils.Interface(implementation.abi).encodeFunctionData('initialize', [...args]);
  const proxy = await deployContract(bre, `${contractName}Proxy`, 'TransparentUpgradeableProxy', implementation.address, proxyAdmin.address, data);

  return proxy.address;
};

export const deployStandardContract = async (bre: BuidlerRuntimeEnvironment, contractName: string, ...args: any[]): Promise<string> => {
  const deployment = await deployContract(bre, contractName, contractName, ...args);
  return deployment.address;
};

export const getUpgradableContract = async (name: string, signer?: Signer | string) => {
  const artifact = require(`../artifacts/${name}.json`);
  const proxy = await ethers.getContract(`${name}Proxy`);
  return ethers.getContractAt(artifact.abi, proxy.address, signer);
};