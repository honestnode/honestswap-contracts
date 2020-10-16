import {ethers} from '@nomiclabs/buidler';
import {expect} from "chai";
import {Contract, Signer, utils} from 'ethers';

export class Account {
  readonly signer: Signer;
  readonly address: string;

  constructor(signer: Signer, address: string) {
    this.signer = signer;
    this.address = address;
  }

  public static initialize = async (signer: Signer): Promise<Account> => {
    const address = await signer.getAddress();
    return new Account(signer, address);
  };

  public connect = (contract: Contract): Contract => {
    return contract.connect(this.signer);
  };
}

export interface NamedAccounts {
  dealer: Account;
  dummy1: Account;
  dummy2: Account;
  supervisor: Account;
}

export const getNamedAccounts = async (): Promise<NamedAccounts> => {
  const accounts = await ethers.getSigners();
  return {
    dealer: await Account.initialize(accounts[0]),
    dummy1: await Account.initialize(accounts[1]),
    dummy2: await Account.initialize(accounts[2]),
    supervisor: await Account.initialize(accounts[9])
  };
};

export const expectAmount = (amount: string, expected: string, decimals: number = 18) : void => {
  if (expected.charAt(0) === '>') {
    expect(amount).to.gt(utils.parseUnits(expected.substr(1), decimals));
  } else if (expected.charAt(0) === '<') {
    expect(amount).to.lt(utils.parseUnits(expected.substr(1), decimals));
  } else if (expected.charAt(0) === '=') {
    expect(amount).to.lt(utils.parseUnits(expected.substr(1), decimals));
  } else {
    expect(amount).to.equal(utils.parseUnits(expected, decimals));
  }
};