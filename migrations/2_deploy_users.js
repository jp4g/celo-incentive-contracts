const UsersContract = artifacts.require("Users")
const AnnouncementsContract = artifacts.require("Announcements")
const BountiesContract = artifacts.require("Bounties")

const name = "MUBC Admin"
const twitterId = "1076569795376676867"
const imageUrl = "AOh14GgHdiwS3EV4d5EXfbXC4mNcEONbthxkBNQllmjz"

module.exports = async (deployer) => {
    await deployer.deploy(UsersContract, name, twitterId, imageUrl, {gas: 6720000, overwrite: false})
    // const users = await UsersContract.deployed()
}