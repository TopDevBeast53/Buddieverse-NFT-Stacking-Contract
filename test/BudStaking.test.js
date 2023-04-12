const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { BigNumber } = ethers;

function timeout(ms) {
	return new Promise(resolve => setTimeout(resolve, ms));
}

describe("BudStaking contract", function () {
	before(async function () {
		const SeedToken = await ethers.getContractFactory("SeedToken");
		const NFTCollection = await ethers.getContractFactory("NFTCollection");
		const Staking = await ethers.getContractFactory("BudStaking");

		this.signers = await ethers.getSigners();
		this.deployer = this.signers[0];
		this.minter = this.signers[1];
		this.bunner = this.signers[2];
		this.bob = this.signers[3];

		this.collection = await NFTCollection.deploy();
    await this.collection.deployed();

		this.seedToken = await SeedToken.deploy(this.minter.address, this.bunner.address);
		await this.seedToken.deployed();

		this.staking = await Staking.deploy(this.collection.address, this.seedToken.address);
		await this.staking.deployed();

		await this.collection.setApprovalForAll(this.staking.address, true);

		await this.collection.mint(this.deployer.address, 1);
		await this.collection.mint(this.deployer.address, 2);
		await this.collection.mint(this.deployer.address, 3);
  });

  // You can nest describe calls to create subsections.
  describe("Deployment", function () {
    it("Stake", async function () {
			await this.staking.stake([1]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(1));

			await time.increase(86400);

			await this.staking.stake([2]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(2));

			await time.increase(86400);

			await this.staking.stake([3]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(3));

			await this.staking.updateRewards();
    });
  });
});
