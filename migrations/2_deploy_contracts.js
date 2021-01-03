const CoreContract = artifacts.require("Core")

module.exports = async (deployer) => {
    await deployer.deploy(CoreContract)
}