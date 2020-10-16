import {BuidlerConfig, usePlugin} from '@nomiclabs/buidler/config';
import * as fs from 'fs';

const infuraKey = fs.readFileSync('.infura').toString().trim();
const mnemonic = fs.readFileSync('.secret').toString().trim();

usePlugin('@nomiclabs/buidler-waffle');
usePlugin("buidler-ethers-v5");
usePlugin('buidler-deploy');

const config: BuidlerConfig = {
  namedAccounts: {
    dealer: 0,
    dummy1: 1,
    dummy2: 2,
    supervisor: 9
  },
  networks: {
    buidlerevm: {
      // loggingEnabled: true,
      gas: 'auto'
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${infuraKey}`,
      accounts: {
        mnemonic: mnemonic
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

export default config;
