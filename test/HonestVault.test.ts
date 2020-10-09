import {ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract} from 'ethers';
import * as MockBasketAsset from '../artifacts/MockBasketAsset.json';
import {honestAssetDeployer} from '../scripts/HonestAsset.deploy';
import {honestConfigurationDeployer} from '../scripts/HonestConfiguration.deploy';
import {honestFeeDeployer} from '../scripts/HonestFee.deploy';
import {honestVaultDeployer} from '../scripts/HonestValut.deploy';
import {yearnV2IntegrationDeployer} from '../scripts/integrations/YearnV2Integration.deploy';
import {Account} from './Common';

describe('HonestVault', () => {
  let supervisor: Account, dummy1: Account, dummy2: Account;
  let honestAsset: Contract, honestConfiguration: Contract,
    yearnV2Integration: Contract, vault: Contract;

  const initializeAccounts = async () => {
    const accounts = await ethers.getSigners();
    supervisor = await Account.initialize(accounts[0]);
    dummy1 = await Account.initialize(accounts[1]);
    dummy2 = await Account.initialize(accounts[2]);
  };

  const deployContracts = async () => {
    honestAsset = await honestAssetDeployer.deployContracts();
    honestConfiguration = await honestConfigurationDeployer.deployContracts(honestAsset);
    yearnV2Integration = await yearnV2IntegrationDeployer.deployContracts(honestConfiguration);
    const fee = await honestFeeDeployer.deployContracts(honestConfiguration);
    vault = await honestVaultDeployer.deployContracts(honestConfiguration, yearnV2Integration, fee);
  };

  const grantRoles = async () => {
    const savingsRole = await honestAsset.SAVINGS();
    await yearnV2Integration.grantRole(savingsRole, vault.address);

    const assetManagerRole = await vault.ASSET_MANAGER();
    await vault.grantRole(assetManagerRole, supervisor.address);
  };

  const mintTokens = async () => {
    const basketAssets: string[] = await honestConfiguration.activeBasketAssets();
    for (let i = 0; i < basketAssets.length; ++i) {
      await mintBasketAsset(basketAssets[i], vault.address, '100');
    }
  };

  const mintBasketAsset = async (asset: string, account: string, amount: string): Promise<void> => {
    const contract = new Contract(asset, MockBasketAsset.abi, supervisor.signer);
    const decimals = await contract.decimals();
    await contract.mint(account, ethers.utils.parseUnits(amount, decimals));
  };

  before(async function () {
    await initializeAccounts();
    await deployContracts();
    await grantRoles();
    await mintTokens();
  });

  it('dummy1 deposit', async () => {
    await vault.deposit(dummy1.address, ethers.utils.parseUnits('100', 18));

    const weight = await vault.weightOf(dummy1.address);
    const share = await vault.shareOf(dummy1.address);
    expect(weight).to.equal(ethers.utils.parseUnits('100', 18));
    expect(share).to.equal(ethers.utils.parseUnits('100', 18));

    const basketAssets: string[] = await honestConfiguration.activeBasketAssets();
    for (let i = 0; i < basketAssets.length; ++i) {
      const contract = new Contract(basketAssets[i], MockBasketAsset.abi, supervisor.signer);
      const decimals = await contract.decimals();
      const balance = await contract.balanceOf(vault.address);
      expect(balance).to.equal(ethers.utils.parseUnits('75', decimals));
    }
  });

  it('dummy2 deposit', async () => {
    await vault.deposit(dummy2.address, ethers.utils.parseUnits('100', 18));

    const weight = await vault.weightOf(dummy2.address);
    const share = await vault.shareOf(dummy2.address);
    expect(weight).to.equal(ethers.utils.parseUnits('100', 18));
    expect(ethers.utils.parseUnits('100', 18).sub(share).abs()).to.lte(ethers.utils.parseUnits('1', 16));

    const basketAssets: string[] = await honestConfiguration.activeBasketAssets();
    for (let i = 0; i < basketAssets.length; ++i) {
      const contract = new Contract(basketAssets[i], MockBasketAsset.abi, supervisor.signer);
      const decimals = await contract.decimals();
      const balance = await contract.balanceOf(vault.address);
      expect(balance).to.equal(ethers.utils.parseUnits('50', decimals));
    }
  });

  it('dummy1 withdraw insufficient', async () => {
    await expect(vault.withdraw(dummy1.address, ethers.utils.parseUnits('200', 18))).to.reverted;
  });

  it('dummy1 withdraw', async () => {
    await vault.withdraw(dummy1.address, ethers.utils.parseUnits('100', 18))

    const weight = await vault.weightOf(dummy1.address);
    const share = await vault.shareOf(dummy1.address);
    expect(weight).to.equal(ethers.BigNumber.from('0'));
    expect(share).to.equal(ethers.BigNumber.from('0'));

    const basketAssets: string[] = await honestConfiguration.activeBasketAssets();
    for (let i = 0; i < basketAssets.length; ++i) {
      const contract = new Contract(basketAssets[i], MockBasketAsset.abi, supervisor.signer);
      const decimals = await contract.decimals();
      const balance = await contract.balanceOf(vault.address);
      expect(balance).to.gte(ethers.utils.parseUnits('75', decimals));
    }
  });

  it('dummy2 withdraw', async () => {
    await vault.withdraw(dummy2.address, ethers.utils.parseUnits('100', 18))

    const weight = await vault.weightOf(dummy2.address);
    const share = await vault.shareOf(dummy2.address);
    expect(weight).to.equal(ethers.BigNumber.from('0'));
    expect(share).to.equal(ethers.BigNumber.from('0'));

    const basketAssets: string[] = await honestConfiguration.activeBasketAssets();
    for (let i = 0; i < basketAssets.length; ++i) {
      const contract = new Contract(basketAssets[i], MockBasketAsset.abi, supervisor.signer);
      const decimals = await contract.decimals();
      const balance = await contract.balanceOf(vault.address);
      expect(balance).to.gte(ethers.utils.parseUnits('100', decimals));
    }
  });
});
