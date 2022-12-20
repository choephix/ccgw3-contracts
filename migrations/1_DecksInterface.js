const DecksInterface = artifacts.require("DecksInterface");

module.exports = function(deployer) {
  deployer.deploy(DecksInterface);
}// as Truffle.Migration;
