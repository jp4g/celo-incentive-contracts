const Migrations = artifacts.require("Migrations")
const TwitterConsumer = artifacts.require("TwitterConsumer")
const IERC20 = artifacts.require("./interfaces/IERC20")

module.exports = async (deployer, network, accounts) => {
  let deployedConsumer, consumerBalance, deployerBalance
  let deployerAccount = accounts[0]
  let chainlink = await IERC20.at(process.env.CHAINLINK_KOVAN)
  console.log('Checking if contract is deployed')
  try{
    deployedConsumer = await TwitterConsumer.deployed()
    console.log('Contract is deployed, checking balance.')
    consumerBalance = await chainlink.balanceOf(deployedConsumer.address)
    consumerBalance = parseFloat(web3.utils.fromWei(consumerBalance, "ether"))
  } catch (error) {
    console.log('No instance deployed. Will deploy if deployer address has minimum LINK balance.')
  }
  if(!consumerBalance || consumerBalance < 1) {
    console.log('Consumer balance is less than 1 LINK or no consumer is deployed. Needs to be funded. Checking deployer balance.')
    deployerBalance = await chainlink.balanceOf(deployerAccount)
    deployerBalance = parseFloat(web3.utils.fromWei(deployerBalance, "ether"))
    if(deployerBalance < 1) throw Error('Deployer balance is less than 1 LINK. Aquire more LINK before migrating.')
    else console.log('Deployer holds minimum required LINK balance. Will fund consumer in later migration step.')
  } else console.log('Consumer has minimum necessary balance. Continuing migration.')

  deployer.deploy(Migrations)
};
