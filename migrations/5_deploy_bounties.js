const UsersContract = artifacts.require("Users")
const BountiesContract = artifacts.require("Bounties")
//const TwitterConsumer = artifacts.require("TwitterConsumer")

module.exports = async (deployer) => {
    const users = await UsersContract.deployed()
    await deployer.deploy(BountiesContract, users.address, {gas: 6720000, overwrite: false})
    //const bounties = await BountiesContract.deployed()
    //await deployer.deploy(TwitterConsumer, bounties.address, {gas: 6720000, overwrite: false})
    // , {gas: 6720000, overwrite: false}
}