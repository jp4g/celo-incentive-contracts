const UsersContract = artifacts.require("Users")
const BountiesContract = artifacts.require("Bounties")

module.exports = async (deployer) => {
    const users = await UsersContract.deployed()
    await deployer.deploy(BountiesContract, users.address)
}