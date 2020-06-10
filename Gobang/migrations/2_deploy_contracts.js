var Gobang = artifacts.require('./Gobang.sol')

module.exports = function (deployer) {
  // deployer.deploy(ConvertLib)
  // deployer.link(ConvertLib, MetaCoin)
  deployer.deploy(Gobang)
}
