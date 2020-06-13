const Monopoly = artifacts.require("Monopoly");

module.exports = function(deployer) {
  deployer.deploy(Monopoly);
  //deployer.link(ConvertLib, MetaCoin);
  //deployer.deploy(MetaCoin);
};
