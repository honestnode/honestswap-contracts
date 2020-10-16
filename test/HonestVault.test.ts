import {deployments, ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {BigNumber, Contract, utils} from 'ethers';
import * as MockBasketAsset from '../artifacts/MockBasketAsset.json';
import {getUpgradableContract} from '../scripts/HonestContract.deploy';
import {getNamedAccounts, NamedAccounts} from '../scripts/HonestContract.test';

describe('HonestVault', () => {
  let namedAccounts: NamedAccounts;
  let honestAsset: Contract, honestConfiguration: Contract, fee: Contract,
    yearnV2Integration: Contract, vault: Contract;
  let basketAssets: string[];

  const initializeAccounts = async () => {
    namedAccounts = await getNamedAccounts();
  };

  const deployContracts = async () => {
    await deployments.fixture();
    honestAsset = await getUpgradableContract('HonestAsset', namedAccounts.dealer.signer);
    yearnV2Integration = await getUpgradableContract('YearnV2Integration', namedAccounts.dealer.signer);
    honestConfiguration = await getUpgradableContract('HonestConfiguration', namedAccounts.dealer.signer);
    fee = await getUpgradableContract('HonestFee', namedAccounts.dealer.signer);
    vault = await getUpgradableContract('HonestVault', namedAccounts.dealer.signer);
    basketAssets = await honestConfiguration.activeBasketAssets();
  };

  const grantRoles = async () => {
    const assetManagerRole = await honestAsset.assetManagerRole();
    namedAccounts.supervisor.connect(honestAsset).grantRole(assetManagerRole, namedAccounts.dealer.address);
    namedAccounts.supervisor.connect(vault).grantRole(assetManagerRole, namedAccounts.dealer.address);
  };

  const mintTokens = async () => {
    for (let i = 0; i < basketAssets.length; ++i) {
      await mintBasketAsset(basketAssets[i], vault.address, '100');
    }
  };

  const mintBasketAsset = async (asset: string, account: string, amount: string): Promise<void> => {
    const contract = await ethers.getContractAt(MockBasketAsset.abi, asset, namedAccounts.supervisor.signer);
    const decimals = await contract.decimals();
    await contract.mint(account, utils.parseUnits(amount, decimals));
  };

  before(async () => {
    await initializeAccounts();
    await deployContracts();
    await grantRoles();
    await mintTokens();
  });

  const assertContractBalances = async (account: string, balances: string[]) => {
    for (let i = 0; i < basketAssets.length; ++i) {
      const contract = await ethers.getContractAt(MockBasketAsset.abi, basketAssets[i], namedAccounts.supervisor.signer);
      const decimals = await contract.decimals();
      const balance = await contract.balanceOf(account);
      if (balances[i].charAt(0) === '>') {
        expect(balance).to.gt(utils.parseUnits(balances[i].substr(1), decimals));
      } else if (balances[i].charAt(0) === '<') {
        expect(balance).to.lt(utils.parseUnits(balances[i].substr(1), decimals));
      } else if (balances[i].charAt(0) === '=') {
        expect(balance).to.lt(utils.parseUnits(balances[i].substr(1), decimals));
      } else {
        expect(balance).to.equal(utils.parseUnits(balances[i], decimals));
      }
    }
  };

  it('dummy1 deposit', async () => {
    await assertContractBalances(vault.address, ['100', '100', '100', '100']);

    await vault.deposit(namedAccounts.dummy1.address, utils.parseUnits('100', 18));

    const weight = await vault.weightOf(namedAccounts.dummy1.address);
    const share = await vault.shareOf(namedAccounts.dummy1.address);
    expect(weight).to.equal(utils.parseUnits('100', 18));
    expect(share).to.equal(utils.parseUnits('100', 18));

    await assertContractBalances(vault.address, ['75', '75', '75', '75']);
  });

  it('dummy2 deposit', async () => {
    await vault.deposit(namedAccounts.dummy2.address, utils.parseUnits('100', 18));

    const weight = await vault.weightOf(namedAccounts.dummy2.address);
    const share = await vault.shareOf(namedAccounts.dummy2.address);
    expect(weight).to.equal(utils.parseUnits('100', 18));
    expect(share).to.lte(utils.parseUnits('100', 18));

    await assertContractBalances(vault.address, ['50', '50', '50', '50']);
  });

  it('distribute proportionally', async () => {
    await vault.distributeProportionally(namedAccounts.dummy1.address, utils.parseUnits('100', 18));

    await assertContractBalances(vault.address, ['25', '25', '25', '25']);
    await assertContractBalances(namedAccounts.dummy1.address, ['25', '25', '25', '25']);
  });

  it('dummy1 withdraw insufficient', async () => {
    await expect(vault.withdraw(namedAccounts.dummy1.address, utils.parseUnits('200', 18))).to.reverted;
  });

  it('dummy1 withdraw', async () => {
    await vault.withdraw(namedAccounts.dummy1.address, utils.parseUnits('100', 18));

    const weight = await vault.weightOf(namedAccounts.dummy1.address);
    const share = await vault.shareOf(namedAccounts.dummy1.address);
    expect(weight).to.equal(BigNumber.from('0'));
    expect(share).to.equal(BigNumber.from('0'));

    await assertContractBalances(vault.address, ['>50', '>50', '>50', '>50']);
  });

  it('distribute manually', async () => {
    await vault.distributeManually(namedAccounts.dummy2.address, [basketAssets[1], basketAssets[2]], [utils.parseUnits('25', 18), utils.parseUnits('25', 18)]);

    await assertContractBalances(namedAccounts.dummy2.address, ['0', '25', '25', '0']);
    await assertContractBalances(vault.address, ['>50', '>25', '>25', '>50']);
  });

  it('dummy2 withdraw', async () => {
    await vault.withdraw(namedAccounts.dummy2.address, utils.parseUnits('100', 18));

    const weight = await vault.weightOf(namedAccounts.dummy2.address);
    const share = await vault.shareOf(namedAccounts.dummy2.address);
    expect(weight).to.equal(BigNumber.from('0'));
    expect(share).to.equal(BigNumber.from('0'));

    await assertContractBalances(vault.address, ['>75', '>50', '>50', '>75']);
  });
});
