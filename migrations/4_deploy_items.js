const UsersContract = artifacts.require("Users")
const ItemsContract = artifacts.require("Items")

module.exports = async (deployer) => {
    const users = await UsersContract.deployed()
    await deployer.deploy(ItemsContract, users.address, {gas: 6720000, overwrite: false})
    // await deployer.deploy(ItemsContract, users.address)
}