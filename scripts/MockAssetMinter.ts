import {ethers} from '@nomiclabs/buidler';
import {Signer, utils} from 'ethers';

async function main() {
  const account = '0x788A6D6Ec9dfd283810e93D0245e5Da283cfE7f1';
  const amount = '100';
  const signers = await ethers.getSigners();
  for(const asset of ['MockDAI', 'MockTUSD', 'MockUSDC', 'MockUSDT']) {
    await mintToken(asset, signers[9], account, amount);
    console.log(`Mint ${amount} ${asset} to ${account}`);
  }
}

async function mintToken(asset: string, signer: Signer, account: string, amount: string) {
  const contract = await ethers.getContract(asset, signer);
  const decimals: number = await contract.decimals();
  await contract.mint(account, utils.parseUnits(amount, decimals));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });