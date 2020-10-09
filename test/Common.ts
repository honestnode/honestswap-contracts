import {Contract, Signer} from 'ethers';

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