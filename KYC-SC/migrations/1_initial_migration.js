const Web3 = require('web3');
const Migrations = artifacts.require("Migrations");
const TruffleConfig = require('../truffle-config.js');

module.exports = async function(deployer, network, addresses) {

  const config = TruffleConfig.networks[network];
  const web3 = new Web3(new Web3.providers.HttpProvider('http://' + config.host + ':' + config.port));
  const adminAccount = await web3.eth.getCoinbase();
  console.log('>> Unlocking account ' + adminAccount);
  web3.eth.personal.unlockAccount(adminAccount, "pwd@123", 36000);
  deployer.deploy(Migrations);
};
