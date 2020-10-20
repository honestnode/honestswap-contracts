import {deployments, ethers} from '@nomiclabs/buidler';
import {expect} from 'chai';
import {BigNumber, Contract, utils} from 'ethers';
import * as ProxyAdminArtifact from '../artifacts/ProxyAdmin.json';
import * as HonestConfigurationArtifact from '../artifacts/HonestConfiguration.json';
import {getUpgradableContract} from '../scripts/HonestContract.deploy';
import {getBlockTimestamp, getNamedAccounts, NamedAccounts, setBlockTimestamp} from '../scripts/HonestContract.test';

describe('Timelock', () => {

  let namedAccounts: NamedAccounts;
  let timelock: Contract, proxyAdmin: Contract, honestConfiguration: Contract, newHonestConfiguration: string;

  const initializeAccounts = async () => {
    namedAccounts = await getNamedAccounts();
  };

  const deployContracts = async () => {
    await deployments.fixture();
    proxyAdmin = await ethers.getContract('ProxyAdmin', namedAccounts.supervisor.signer);
    timelock = await ethers.getContract('Timelock', namedAccounts.supervisor.signer);
    honestConfiguration = await getUpgradableContract('HonestConfiguration', namedAccounts.supervisor.signer);
    newHonestConfiguration = (await deployments.deploy('NewHonestConfigurationImplementation', {
      contract: 'HonestConfiguration',
      from: namedAccounts.supervisor.address
    })).address;
  };

  const grantTimelockRoles = async () => {
    await proxyAdmin.transferOwnership(timelock.address);
    await honestConfiguration.transferOwnership(timelock.address);
  };

  before(async () => {
    await initializeAccounts();
    await deployContracts();
    await grantTimelockRoles();
  });

  it('current sensitive should reverted', async () => {
    await expect(proxyAdmin.upgrade(honestConfiguration.address, namedAccounts.dummy1.address)).to.reverted;
    await expect(honestConfiguration.grantRole('0x0000000000000000000000000000000000000000000000000000000000000000', namedAccounts.dummy1.address)).to.reverted;
  });

  it('control HonestConfiguration', async () => {
    const oldRate = await honestConfiguration.swapFeeRate();
    expect(oldRate).to.equal(utils.parseUnits('1', 16));

    const data = new utils.Interface(HonestConfigurationArtifact.abi).encodeFunctionData('setSwapFeeRate', [utils.parseUnits('2', 16)]);
    const timestamp = await getBlockTimestamp();
    const eta = timestamp + 605000;
    await timelock.queueTransaction(honestConfiguration.address, BigNumber.from(0), data, BigNumber.from(eta));

    await expect(timelock.executeTransaction(honestConfiguration.address, BigNumber.from(0), data, BigNumber.from(eta))).to.reverted;
    await setBlockTimestamp(eta);

    await timelock.executeTransaction(honestConfiguration.address, BigNumber.from(0), data, BigNumber.from(eta));

    const newRate = await honestConfiguration.swapFeeRate();
    expect(newRate).to.equal(utils.parseUnits('2', 16));
  });
  //
  // it('upgrade proxy', async () => {
  //   let implementation = await proxyAdmin.getProxyImplementation(honestConfiguration.address);
  //   expect(implementation).not.equal(newHonestConfiguration);
  //
  //   const data = new utils.Interface(ProxyAdminArtifact.abi).encodeFunctionData('upgrade', [honestConfiguration.address, newHonestConfiguration]);
  //   const timestamp = await getBlockTimestamp();
  //   const eta = timestamp + 605000;
  //
  //   await timelock.queueTransaction(proxyAdmin.address, BigNumber.from('0'), data, BigNumber.from(eta));
  //   await expect(timelock.executeTransaction(honestConfiguration.address, BigNumber.from(0), data, BigNumber.from(eta))).to.reverted;
  //   await setBlockTimestamp(eta);
  //
  //   await timelock.executeTransaction(proxyAdmin.address, BigNumber.from('0'), data, BigNumber.from(eta));
  //
  //   implementation = await proxyAdmin.getProxyImplementation(honestConfiguration.address);
  //   expect(implementation).to.equal(newHonestConfiguration);
  // });
});