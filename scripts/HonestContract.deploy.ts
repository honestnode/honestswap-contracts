import * as bre from '@nomiclabs/buidler';
import {ethers, upgrades} from '@nomiclabs/buidler';
import {Contract, ContractFactory} from 'ethers';

export abstract class HonestContractDeployer {

  protected async deploy(name: string, ...args: any[]): Promise<Contract> {
    const contract: ContractFactory = await ethers.getContractFactory(name);
    return await contract.deploy(...args);
  }

  protected async deployUpgradable(name: string, ...args: any[]): Promise<Contract> {
    const contract = await ethers.getContractFactory(name);
    return await upgrades.deployProxy(contract, args, {unsafeAllowCustomTypes: true});
  }
}