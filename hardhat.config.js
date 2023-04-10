require('dotenv').config();
require("@nomiclabs/hardhat-waffle");
require('solidity-coverage')
require('hardhat-gas-reporter')


// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
	const accounts = await hre.ethers.getSigners();

	for (const account of accounts) {
		console.log(account.address);
	}
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	defaultNetwork: "localhost",
	gasReporter: {
		currency: 'USD',
		enabled: true
	},
	networks: {
		localhost: {},
		// hardhat: {
		// 	forking: {
		// 		enabled: process.env.FORKING === "true",
		// 		url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
		// 	},
		// 	chainId: 31337,
		// },
		// ropsten: {
		// 	url: `https://ropsten.infura.io/v3/`,
		// 	accounts: [process.env.PRIVATE_KEY, process.env.PRIVATE_KEY2],
		// 	chainId: 3,
		// 	gasPrice: 1000000,
		// 	gasMultiplier: 2,
		// },
		// volta: {
		// 	url: "https://volta-internal-archive.energyweb.org", //`https://volta-rpc.energyweb.org`,
		// 	accounts: [process.env.PRIVATE_KEY, process.env.PRIVATE_KEY2],
		// 	chainId: 73799,
		// 	gasPrice: 1000000,
		// 	gasMultiplier: 2,
		// },
		// ewc: {
		// 	url: `https://rpc-ewc.carbonswap.exchange`,
		// 	accounts: [process.env.PRIVATE_KEY, process.env.PRIVATE_KEY2],
		// 	chainId: 246,
		// 	gasPrice: 1000,
		// 	gasMultiplier: 2,
		// },
		// ropsten: {
		// 	url: "https://ropsten.infura.io/v3/",
		// 	accounts: [process.env.PRIVATE_KEY, process.env.PRIVATE_KEY2],
		// 	chainId: 3,
		// 	gasPrice: 1000000,
		// 	gasMultiplier: 2,
		// },
		goerli : {
			url: "https://goerli.infura.io/v3/",
			accounts: [process.env.PRIVATE_KEY],
			chainId: 5,
			gasPrice: 1000000,
			gasMultiplier: 2,
		},
		moonriver: {
			url: `https://rpc.api.moonriver.moonbeam.network`,
			accounts: [process.env.PRIVATE_KEY, process.env.PRIVATE_KEY2],
			chainId: 1285,
			gasPrice: 1900000000,
			gasMultiplier: 2,
		},
		moonbeam: {
			url: `https://rpc.api.moonbeam.network`,
			accounts: [process.env.PRIVATE_KEY, process.env.PRIVATE_KEY2],
			chainId: 1284,
			gasPrice: 100000000000,
			gasMultiplier: 2,
		},
	},
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
	}
};
