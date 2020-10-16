import {deployments, ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {Contract, utils} from 'ethers';
import {getUpgradableContract} from '../scripts/HonestContract.deploy';
import {getNamedAccounts, NamedAccounts} from '../scripts/HonestContract.test';
import * as HonestAssetArtifact from '../artifacts/HonestAsset.json';

describe('ProxyAdmin', () => {

  let namedAccounts: NamedAccounts;
  let proxyAdmin: Contract, honestAsset: Contract;

  const initializeAccounts = async () => {
    namedAccounts = await getNamedAccounts();
  };

  const deployContracts = async () => {
    await deployments.fixture();
    proxyAdmin = await ethers.getContract('ProxyAdmin', namedAccounts.supervisor.signer);
    honestAsset = await getUpgradableContract('HonestAsset', namedAccounts.supervisor.signer);
  };

  before(async () => {
    await initializeAccounts();
    await deployContracts();
  });

  it('validate proxy admin', async () => {
    const admin = await proxyAdmin.getProxyAdmin(honestAsset.address);
    expect(admin).to.equal(proxyAdmin.address);
  });

  it('validate implement', async () => {
    const expected = await ethers.getContract('HonestAssetImplementation');
    const implementation = await proxyAdmin.getProxyImplementation(honestAsset.address);
    expect(implementation).to.equal(expected.address);
  });

  it('upgrade', async () => {
    const before = await proxyAdmin.getProxyImplementation(honestAsset.address);
    const beforeName = await honestAsset.name();
    const newHonestAsset = await deployments.deploy('NewHonestAssetImplementation1', {contract: 'HonestAsset', from: namedAccounts.supervisor.address});
    await proxyAdmin.upgrade(honestAsset.address, newHonestAsset.address);
    const after = await proxyAdmin.getProxyImplementation(honestAsset.address);
    const afterName = await honestAsset.name();
    expect(after).to.equal(newHonestAsset.address);
    expect(after).not.equal(before);
    expect(afterName).to.equal(beforeName);
  });

  it('upgrade and call', async () => {
    await honestAsset.grantRole('0x0000000000000000000000000000000000000000000000000000000000000000', proxyAdmin.address);
    const before = await proxyAdmin.getProxyImplementation(honestAsset.address);

    const newHonestAsset = await deployments.deploy('NewHonestAssetImplementation2', {contract: 'HonestAsset', from: namedAccounts.supervisor.address});
    const data = new utils.Interface(HonestAssetArtifact.abi).encodeFunctionData('grantRole', ['0x81349814bed7dfa157b76a21259a8d40c0afbebce228b6fa6309925210da2d6d', namedAccounts.dealer.address]);
    await proxyAdmin.upgradeAndCall(honestAsset.address, newHonestAsset.address, data);

    const after = await proxyAdmin.getProxyImplementation(honestAsset.address);
    expect(after).to.equal(newHonestAsset.address);
    expect(after).not.equal(before);
  });
});