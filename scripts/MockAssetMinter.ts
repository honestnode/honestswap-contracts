import {ethers} from '@nomiclabs/buidler';
import {Signer, utils} from 'ethers';

async function main() {
  const account = '0xb17Bf1B0dEa8097f7f100c1AC43784320c50c27C';
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