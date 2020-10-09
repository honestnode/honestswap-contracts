import {BuidlerConfig, usePlugin} from '@nomiclabs/buidler/config';
import * as fs from 'fs';

const infuraKey = fs.readFileSync('.infura').toString().trim();
const mnemonic = fs.readFileSync('.secret').toString().trim();

usePlugin('@nomiclabs/buidler-waffle');
usePlugin('@openzeppelin/buidler-upgrades');

const config: BuidlerConfig = {
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
