import {ethers} from '@nomiclabs/buidler';
import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';

const setupPrivileges: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {

  const supervisor = (await bre.getNamedAccounts())['supervisor'];
  const proxyAdmin = await ethers.getContract('DelayedProxyAdmin', supervisor);
  const honestAsset = await ethers.getContract('HonestAsset', supervisor);
  const honestVault = await ethers.getContract('HonestVault', supervisor);
  const honestAssetManager = await ethers.getContract('HonestAssetManager', supervisor);
  const yearnV2Integration = await ethers.getContract('YearnV2Integration', supervisor);
  const honestFee = await ethers.getContract('HonestFee', supervisor);

  const vaultRole = await honestAsset.VAULT();
  await proxyAdmin.grantProxyRole(yearnV2Integration.address, vaultRole, honestVault.address);
  await proxyAdmin.grantProxyRole(honestFee.address, vaultRole, honestVault.address);

  const assetManagerRole = await honestAsset.ASSET_MANAGER();
  await proxyAdmin.grantProxyRole(honestAsset.address, assetManagerRole, honestAssetManager.address);
  await proxyAdmin.grantProxyRole(honestVault.address, assetManagerRole, honestAssetManager.address);

  switch (bre.network.name) {
    case 'buidlerevm':
      break;
    default:
      await proxyAdmin.revokeRole(await proxyAdmin.GOVERNOR(), supervisor);
      break;
  }
};

export default setupPrivileges;