require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

// The next line is part of the sample project, you don't need it in your
// project. It imports a Hardhat task definition, that can be used for
// testing the frontend.
require("./tasks/faucet");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
		compilers: [
			{
				version: "0.8.9",
				settings: {
					optimizer: {
						enabled: true,
						runs: 1000,
					},
				}
			}
		]
	},
	defaultNetwork: "localhost",
  networks: {
		localhost: {

    },
    hardhat: {
      chainId: 1337, // We set 1337 to make interacting with MetaMask simpler
    },
		exosama: {
			url: "https://rpc.exosama.com",
			accounts: [`0x${process.env.PRIVATE_KEY}`],
			chainId: 2109,
			blockGasLimit: 7770285457770297480000,
		},
    bsc: {
      url: "https://bsc-testnet.public.blastapi.io",
			accounts: [`0x${process.env.PRIVATE_KEY}`],
			chainId: 97,
    }
  }
};
