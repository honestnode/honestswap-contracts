import {ethers} from '@nomiclabs/buidler';
import {BuidlerRuntimeEnvironment} from '@nomiclabs/buidler/types';
import {Contract, ContractFactory} from 'ethers';

export abstract class HonestContractDeployer {

  protected async deploy(name: string, ...args: any[]): Promise<Contract> {
    const contract: ContractFactory = await ethers.getContractFactory(name);
    return await contract.deploy(...args);
  }

  protected async deployUpgradable(name: string, ...args: any[]): Promise<Contract> {
    return new Contract('', []);
    // const contract = await ethers.getContractFactory(name);
    // return await upgrades.deployProxy(contract, args, {unsafeAllowCustomTypes: true});
  }
}

export const deployUpgradableContract = async (bre: BuidlerRuntimeEnvironment, contractName: string, ...args: any[]): Promise<string> => {
  const {deployments, getNamedAccounts} = bre;
  const {deploy, log, get} = deployments;
  const {supervisor} = await getNamedAccounts();

  const proxyAdmin = await get('DelayedProxyAdmin');

  log(`--- ${contractName}`)
  const contract = await deploy(contractName, {
    from: supervisor,
    proxy: {owner: proxyAdmin.address, methodName: 'initialize'},
    log: true,
    args: [proxyAdmin.address, ...args]
  });

  return contract.address;
};

export const deployContract = async (bre: BuidlerRuntimeEnvironment, contractName: string, ...args: any[]): Promise<string> => {
  const {deployments, getNamedAccounts} = bre;
  const {deploy, log} = deployments;
  const {supervisor} = await getNamedAccounts();

  log(`--- ${contractName}`)
  const contract = await deploy(contractName, {
    from: supervisor,
    log: true,
    args: args
  });

  return contract.address;
};