import {deployments, ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, utils} from 'ethers';
import * as yTokenV2 from '../../artifacts/MockYTokenV2.json';
import {getNamedAccounts, NamedAccounts} from '../../scripts/HonestContract.test';

describe('YearnV2Integration', () => {

  let namedAccounts: NamedAccounts;
  let proxyAdmin: Contract, honestConfiguration: Contract, yearnV2Integration: Contract, vaultRole: string;

  const initializeAccounts = async () => {
    namedAccounts = await getNamedAccounts();
  };

  const deployContracts = async () => {
    await deployments.fixture();

    proxyAdmin = await ethers.getContract('DelayedProxyAdmin', namedAccounts.supervisor.signer);
    honestConfiguration = await ethers.getContract('HonestConfiguration', namedAccounts.dummy1.signer);
    yearnV2Integration = await ethers.getContract('YearnV2Integration', namedAccounts.dummy1.signer);
  };

  before(async () => {
    await initializeAccounts();
    await deployContracts();
    vaultRole = await yearnV2Integration.VAULT();
  });

  it('invest without authorization', async () => {
    const assets = await honestConfiguration.activeBasketAssets();
    const account = namedAccounts.dummy1.address;
    for (const asset of assets) {
      await expect(yearnV2Integration.invest(account, asset, utils.parseUnits('100', 18))).to.reverted;
    }
  });

  it('invest', async () => {
    await proxyAdmin.grantProxyRole(yearnV2Integration.address, vaultRole, namedAccounts.dummy1.address);
    const account = namedAccounts.dummy1.address;

    const assets = await honestConfiguration.activeBasketAssets();
    for (const asset of assets) {
      const token = await ethers.getContractAt(yTokenV2.abi, asset, namedAccounts.supervisor.signer);
      const decimals = await token.decimals();
      await token.mint(account, utils.parseUnits('100', decimals));
      const dummy1Token = namedAccounts.dummy1.connect(token);
      await dummy1Token.approve(yearnV2Integration.address, utils.parseUnits('100', decimals));
      const price = await yearnV2Integration.priceOf(asset);
      const shares = utils.parseUnits('100', decimals + 18).div(price).mul(utils.parseUnits('1', 18 - decimals));
      await yearnV2Integration.invest(account, asset, utils.parseUnits('100', decimals));
      expect(await yearnV2Integration.shareOf(asset)).to.lte(shares);
    }

    await proxyAdmin.revokeProxyRole(yearnV2Integration.address, vaultRole, namedAccounts.dummy1.address);
  });

  it('collect without authorization', async () => {
    const assets = await honestConfiguration.activeBasketAssets();
    const account = namedAccounts.dummy1.address;

    for (const asset of assets) {
      await expect(yearnV2Integration.collect(account, asset, utils.parseUnits('100', 18))).to.reverted;
    }
  });

  it('collect', async () => {
    const account = namedAccounts.dummy1.address;
    await proxyAdmin.grantProxyRole(yearnV2Integration.address, vaultRole, namedAccounts.dummy1.address);

    const assets = await honestConfiguration.activeBasketAssets();
    for (const asset of assets) {
      const token = new Contract(asset, yTokenV2.abi, namedAccounts.dummy1.signer);
      const decimals = await token.decimals();
      const shares = await yearnV2Integration.shareOf(asset);
      await yearnV2Integration.collect(account, asset, shares);
      const balance = await token.balanceOf(account);
      expect(balance).to.gte(utils.parseUnits('100', decimals));
    }

    await proxyAdmin.revokeProxyRole(yearnV2Integration.address, vaultRole, namedAccounts.dummy1.address);
  });
});