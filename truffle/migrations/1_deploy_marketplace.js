//We are requring the smart contract file
const Marketplace = artifacts.require("Marketplace");

module.exports = function (deployer, _network, accounts) {
  //This means that the smartcontract is deployed by the account 0
  //Hence we can also say that accounts[0] is the manager of the smart contract
  deployer.deploy(Marketplace, accounts[0], accounts[4]);
};
