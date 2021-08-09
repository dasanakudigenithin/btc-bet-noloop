const Migrations = artifacts.require("BTCBettingChallenge");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
