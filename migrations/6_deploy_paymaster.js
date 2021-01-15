const UsersContract = artifacts.require("Users")
const AnnouncementsContract = artifacts.require("Announcements")
const ItemsContract = artifacts.require("Items")
const BountiesContract = artifacts.require("Bounties")
const RelayHubInterface = artifacts.require("InterfaceRelayHub")
const PaymasterContract = artifacts.require("OrgTokenPaymaster")

module.exports = async (deployer, network, accounts) => {

    const usersAddress = (await UsersContract.deployed()).address
    const announcementsAddress = (await AnnouncementsContract.deployed()).address
    const itemsAddress = (await ItemsContract.deployed()).address
    const bountiesAddress = (await BountiesContract.deployed()).address

    await deployer.deploy(PaymasterContract, {gas: 6720000, overwrite: false})
    const paymaster = await PaymasterContract.deployed()
    await paymaster.setRelayHub(process.env.RELAY_KOVAN)
    await paymaster.setTargets(usersAddress, announcementsAddress, itemsAddress, bountiesAddress)
    await paymaster.setTrustedForwarder(process.env.FORWARDER_KOVAN)
    const relayHub = await RelayHubInterface.at(process.env.RELAY_KOVAN)
    await relayHub.depositFor(paymaster.address, { from: accounts[0], value: 1e18 })
}