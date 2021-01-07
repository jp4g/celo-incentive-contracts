const UsersContract = artifacts.require("Users")
const AnnouncementsContract = artifacts.require("Announcements")
const BountiesContract = artifacts.require("Bounties")

const name = "MUBC Admin"
const twitterId = "mubcblockchain"
const imageUrl = "AOh14GgHdiwS3EV4d5EXfbXC4mNcEONbthxkBNQllmjz"

module.exports = async (deployer) => {
    await deployer.deploy(UsersContract, name, twitterId, imageUrl)
    const users = await UsersContract.deployed()
}