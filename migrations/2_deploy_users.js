const UsersContract = artifacts.require("Users")

const name = "MUBC Admin"
const twitterId = "1076569795376676867"
const imageUrl = "AOh14GgHdiwS3EV4d5EXfbXC4mNcEONbthxkBNQllmjz"

module.exports = async (deployer) => {
    await deployer.deploy(
        UsersContract,
        name,
        twitterId,
        imageUrl,
        process.env.FORWARDER_KOVAN,
        { gas: 6720000, overwrite: false })
}