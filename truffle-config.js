const HDWalletProvider = require('@truffle/hdwallet-provider')
require("dotenv").config()

module.exports = {

  networks: {
    develop: {
      provider: () => { return new HDWalletProvider(process.env.MNEMONIC, 'http://0.0.0.0:8545', 0, 10 )},
      gasLimit: 3000000,
      network_id: "*",
    },
    ropsten: {
      provider: () => { return new HDWalletProvider(process.env.MNEMONIC, 'https://ropsten.' + process.env.INFURA, 0, 10 )},
      network_id: "3",
    },
    kovan: {
      provider: () => { return new HDWalletProvider(process.env.MNEMONIC, 'https://kovan.' + process.env.INFURA, 0, 10 )},
      network_id: "42",
    },
    rinkeby: {
      provider: () => { return new HDWalletProvider(process.env.MNEMONIC, 'https://rinkeby.' + process.env.INFURA, 0, 10 )},
      network_id: "4",
    }
     
  },
  compilers: {
    solc: {
      version: "0.6.1",
      settings: {
       optimizer: {
         enabled: false,
         runs: 200
       }
      }
    }
  }
}
