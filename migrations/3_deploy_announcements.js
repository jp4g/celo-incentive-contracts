const UsersContract = artifacts.require("Users")
const AnnouncementsContract = artifacts.require("Announcements")

module.exports = async (deployer) => {
    const users = await UsersContract.deployed()
    await deployer.deploy(
        AnnouncementsContract,
        users.address,
        process.env.FORWARDER_KOVAN,
        { gas: 6720000, overwrite: false })
}