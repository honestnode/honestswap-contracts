const Nexus = artifacts.require("Nexus");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(Nexus, accounts[0]);
};
