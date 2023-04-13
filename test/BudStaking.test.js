const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { BigNumber } = ethers;

const SECONDS_IN_DAY = 86400;

describe("BudStaking contract", function () {
	beforeEach(async function () {
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

		await this.seedToken.connect(this.minter).mint(this.staking.address, 3000000);

		await this.collection.connect(this.deployer).setApprovalForAll(this.staking.address, true);
		await this.collection.connect(this.minter).setApprovalForAll(this.staking.address, true);
		await this.collection.connect(this.bunner).setApprovalForAll(this.staking.address, true);
		await this.collection.connect(this.bob).setApprovalForAll(this.staking.address, true);

		await this.collection.mint(this.deployer.address, 1);
		await this.collection.mint(this.deployer.address, 2);
		await this.collection.mint(this.minter.address, 3);
  });

  // You can nest describe calls to create subsections.
  describe("Deployment", function () {
		// it("should stake successfully", async function () {
		// 	await this.staking.stake([1]);
		// 	await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(1));

		// 	await this.staking.stake([2]);
		// 	await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(2));

		// 	await this.staking.connect(this.minter).stake([3]);
		// 	await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(3));
    // });

		// it("should stake and withdraw", async function () {
		// 	await this.staking.stake([1]);
		// 	await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(1));

		// 	await this.staking.withdraw([1]);
		// 	await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(0));
    // });

		// it("should stake and withdraw multiple tokens", async function () {
		// 	await this.staking.stake([1, 2]);
		// 	await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(2));

		// 	await this.staking.connect(this.minter).stake([3]);
		// 	await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(3));

		// 	await this.staking.connect(this.minter).withdraw([3]);
		// 	await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(2));
			
		// 	await this.staking.withdraw([1, 2]);
		// 	await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(0));
    // });

		// it("should claim rewards", async function () {
		// 	await this.staking.stake([1]);
		// 	await time.increase(SECONDS_IN_DAY);

		// 	await this.staking.claimRewards();
		// 	await expect(await this.seedToken.balanceOf(this.deployer.address)).to.eql(BigNumber.from(5555));
    // });

		// it("should get user staked info without error", async function () {
		// 	const stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
		// 	await expect(stakeInfo[0].length).to.eq(0);
		// 	await expect(stakeInfo[1]).to.eq(BigNumber.from(0));
    // });

    // it("should get user stake information", async function () {
		// 	await this.staking.stake([1]);
		// 	await time.increase(SECONDS_IN_DAY);

		// 	const stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
		// 	await expect(stakeInfo[0].length).to.eq(1);
		// 	await expect(stakeInfo[1]).to.eq(BigNumber.from(5555));
    // });

		it("should get user rewards", async function () {
			await this.staking.stake([1]);
			await time.increase(SECONDS_IN_DAY * 180);

			const stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			console.log('stakeInfo', stakeInfo)
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from(5555));
    });
  });
});
