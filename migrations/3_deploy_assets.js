const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const HonestAsset = artifacts.require('HonestAsset');

module.exports = async (deployer) => {
  const asset = await deployProxy(HonestAsset, ['Honest USD', 'hUSD'], { deployer, unsafeAllowCustomTypes: true });

  console.log(asset.address);
};