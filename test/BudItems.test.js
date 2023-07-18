const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { BigNumber } = ethers;

const SECONDS_IN_DAY = 86400;

const formatEther = (value, precision = 4) => {
	const ethValue = ethers.utils.formatEther(value);
	const factor = Math.pow(10, precision);
	return (Math.floor(ethValue * factor) / factor).toString();
}

describe("BudItems contract", function () {
	beforeEach(async function () {
		const BudItems = await ethers.getContractFactory("BudItems");

		this.signers = await ethers.getSigners();
		this.deployer = this.signers[0];
		this.alice = this.signers[1];
		this.bunner = this.signers[2];
		this.bob = this.signers[3];

		const uri = "https://ipfs.io/ipfs/QmQYB5pQDN9zsJQ5PAL4Tc9zWtYpnoKfhb2puM7HCAVGQL/{id}.json";
		
		this.budItems = await BudItems.deploy(uri);
		await this.budItems.deployed();
  });

  // You can nest describe calls to create subsections.
  describe("Deployment", function () {
		it("should mint successfully", async function () {
			await this.budItems.mintBatch(this.deployer.address, [1], [2], '0x00');
			await this.budItems.mintBatch(this.alice.address, [2], [3], '0x00');
			await this.budItems.mintBatch(this.deployer.address, [2], [5], '0x00');

			const balances = await this.budItems.ownedTokenBalances(this.deployer.address);
			console.log('balances', balances);
    });
  });
});
