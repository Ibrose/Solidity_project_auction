// var Migrations = artifacts.require("./Migrations.sol");
var migrations = artifacts.require("Migrations");

module.exports = function(deployer) {
  deployer.deploy(migrations);
};
