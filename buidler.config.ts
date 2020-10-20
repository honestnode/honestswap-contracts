import {BuidlerConfig, usePlugin} from '@nomiclabs/buidler/config';
import config from 'config';

usePlugin('@nomiclabs/buidler-waffle');
usePlugin("buidler-ethers-v5");
usePlugin('buidler-deploy');

const buidlerConfig: BuidlerConfig = {
  namedAccounts: {
    dealer: 0,
    dummy1: 1,
    dummy2: 2,
    supervisor: 9
  },
  paths: {
    deploy: 'deploy',
    deployments: 'deployments',
  },
  networks: {
    buidlerevm: {
      // loggingEnabled: true,
      gas: 'auto',
    },
    localhost: {
      url: config.get<string>('ganache.url'),
      accounts: {
        mnemonic: config.get<string>('ganache.mnemonic')
      }
    },
    ropsten: {
      url: config.get<string>('ropsten.url'),
      accounts: {
        mnemonic: config.get<string>('ropsten.mnemonic')
      }
    },
    rinkeby: {
      url: config.get<string>('rinkeby.url'),
      accounts: {
        mnemonic: config.get<string>('rinkeby.mnemonic')
      }
    }
  },
  solc: {
    version: '0.6.12',
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};

export default buidlerConfig;
