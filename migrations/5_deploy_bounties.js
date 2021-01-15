const UsersContract = artifacts.require("Users")
const BountiesContract = artifacts.require("Bounties")
const TwitterConsumer = artifacts.require("TwitterConsumer")
const IERC20 = artifacts.require('IERC20')

module.exports = async (deployer, network, accounts) => {
    const users = await UsersContract.deployed()
    await deployer.deploy(BountiesContract, users.address, {gas: 6720000, overwrite: false})
    const bounties = await BountiesContract.deployed()
    const consumer = await deployer.deploy(TwitterConsumer, bounties.address, {gas: 6720000, overwrite: false})
    let deployerAccount = accounts[0]
    let chainlink = await IERC20.at(process.env.CHAINLINK_KOVAN)
    let consumerBalance = await chainlink.balanceOf(consumer.address)
    consumerBalance = parseFloat(web3.utils.fromWei(consumerBalance, "ether"))
    if(consumerBalance < 1) {
        console.log('Funding consumer with LINK...')
        await chainlink.transfer(consumer.address, web3.utils.toWei('1', 'ether'), {from: deployerAccount})
        console.log('Consumer funded.')
    }

    // // , {gas: 6720000, overwrite: false}
}