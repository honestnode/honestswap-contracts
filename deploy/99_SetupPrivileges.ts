import {ethers} from '@nomiclabs/buidler';
import {BuidlerRuntimeEnvironment, DeployFunction} from '@nomiclabs/buidler/types';
import {Contract} from 'ethers';
import {getUpgradableContract} from '../scripts/HonestContract.deploy';

const setupPrivileges: DeployFunction = async (bre: BuidlerRuntimeEnvironment) => {

  const supervisor = (await bre.getNamedAccounts())['supervisor'];
  const proxyAdmin = await ethers.getContract('ProxyAdmin', supervisor);
  const honestAsset = await getUpgradableContract('HonestAsset', supervisor);
  const honestConfiguration = await getUpgradableContract('HonestConfiguration', supervisor);
  const honestVault = await getUpgradableContract('HonestVault', supervisor);
  const honestAssetManager = await getUpgradableContract('HonestAssetManager', supervisor);
  const yearnV2Integration = await getUpgradableContract('YearnV2Integration', supervisor);
  const honestFee = await getUpgradableContract('HonestFee', supervisor);
  const timelock = await ethers.getContract('Timelock', supervisor);

  await yearnV2Integration.grantRole('0x81349814bed7dfa157b76a21259a8d40c0afbebce228b6fa6309925210da2d6d', honestVault.address);
  await honestFee.grantRole('0x81349814bed7dfa157b76a21259a8d40c0afbebce228b6fa6309925210da2d6d', honestVault.address);

  await honestAsset.grantRole('0x6bc9af616991ee5669a4db9fdf1be40cf0f301aaa197206636e2f4b9a3c7af3b', honestAssetManager.address);
  await honestVault.grantRole('0x6bc9af616991ee5669a4db9fdf1be40cf0f301aaa197206636e2f4b9a3c7af3b', honestAssetManager.address);

  switch (bre.network.name) {
    case 'buidlerevm':
      break;
    default:
      await proxyAdmin.transferOwnership(timelock.address);
      await honestAsset.transferOwnership(timelock.address);
      await honestConfiguration.transferOwnership(timelock.address);
      await honestFee.transferOwnership(timelock.address);
      await yearnV2Integration.transferOwnership(timelock.address);
      await honestVault.transferOwnership(timelock.address);
      await honestAssetManager.transferOwnership(timelock.address);
      break;
  }
};

export default setupPrivileges;