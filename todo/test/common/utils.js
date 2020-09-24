const BN = require('bn.js');

const Constants = {
  VOID_ADDRESS: '0x0000000000000000000000000000000000000000'
};

const BigNumbers = {

  shift: (value, offset = 18) => {
    if (offset === 0) {
      return new BN(value);
    } else if (offset > 0) {
      return new BN(value).mul(new BN(10).pow(new BN(offset)));
    } else {
      return new BN(value).div(new BN(10).pow(new BN(-offset)));
    }
  },

  unshift: (value, offset = 18) => {
    if (offset === 18) {
      return value.toString();
    } else if (offset > 18) {
      throw new Error('illegal numbers');
    } else {
      return value.mul(new BN(10).pow(new BN(18-offset))).toString();
    }
  }
}

const Deployer = {

  deploy: async (deployer, contract, ...args) => {
    if (args.length > 0) {
      await deployer.deploy(contract, ...args);
    } else {
      await deployer.deploy(contract);
    }
    return await contract.deployed();
  }
};

module.exports = {
  BigNumbers: BigNumbers,
  Deployer: Deployer,
  Constants: Constants,
}