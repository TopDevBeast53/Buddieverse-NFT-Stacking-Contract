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
		this.alice = this.signers[1];
		this.bunner = this.signers[2];
		this.bob = this.signers[3];

		this.collection = await NFTCollection.deploy();
    await this.collection.deployed();

		this.seedToken = await SeedToken.deploy(this.deployer.address, this.deployer.address);
		await this.seedToken.deployed();

		this.staking = await Staking.deploy(this.collection.address, this.seedToken.address);
		await this.staking.deployed();

		const ethersToWei = ethers.utils.parseUnits("3000000", "ether");
		await this.seedToken.mint(this.staking.address, ethersToWei);

		await this.collection.connect(this.deployer).setApprovalForAll(this.staking.address, true);
		await this.collection.connect(this.alice).setApprovalForAll(this.staking.address, true);
		await this.collection.connect(this.bunner).setApprovalForAll(this.staking.address, true);
		await this.collection.connect(this.bob).setApprovalForAll(this.staking.address, true);

		await this.collection.mint(this.deployer.address, 1);
		await this.collection.mint(this.deployer.address, 2);
		await this.collection.mint(this.alice.address, 3);
  });

  // You can nest describe calls to create subsections.
  describe("Deployment", function () {
		/*it("should be approved", async function () {
			await expect(await this.collection.isApprovedForAll(this.staking.address, this.deployer.address)).to.eql(true);

			const rewards = ethers.utils.parseUnits("3000000", "ether");
			await expect(await this.seedToken.allowance(this.staking.address, this.deployer.address)).to.eql(rewards);
    });*/

		it("should stake successfully", async function () {
			await this.staking.stake([1]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(1));

			// await this.staking.stake([2]);
			// await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(2));

			await this.staking.connect(this.alice).stake([3]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(3));
    });

		/*it("should stake and unstake", async function () {
			await this.staking.stake([1]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(1));

			await this.staking.unstake([1]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(0));
    });

		it("should stake and unstake multiple tokens", async function () {
			await this.staking.stake([1, 2]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(2));

			await this.staking.connect(this.alice).stake([3]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(3));

			await this.staking.connect(this.alice).unstake([3]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(2));
			
			await this.staking.unstake([1, 2]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(0));
    });

		it("should claim rewards", async function () {
			await this.staking.stake([1]);
			await time.increase(SECONDS_IN_DAY);

			await this.staking.claimRewards();
			await expect(await this.seedToken.balanceOf(this.deployer.address)).to.eql(BigNumber.from("5555555555555555555555"));
    });

		it("should get user staked info without error", async function () {
			const stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(0);
			await expect(stakeInfo[1]).to.eq(BigNumber.from(0));
    });

    it("should get user stake information 1", async function () {
			await this.staking.stake([1]);
			await time.increase(7600);

			await this.staking.connect(this.alice).stake([3]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(2));
			
			await time.increase(3600 * 24 * 2);

			const info2 = await this.staking.userStakeInfo(this.alice.address);
			await expect(info2[0].length).to.eq(1);
			await expect(info2[1]).to.gt(BigNumber.from("0"));
    });

		it("should get user stake information 2", async function () {
			await this.staking.stake([1]);
			await time.increase(3600 * 24 + 10);

			const stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.gt(BigNumber.from("0"));

			await this.staking.connect(this.alice).stake([3]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(2));
			
			await time.increase(3600 * 24 * 4);

			const info2 = await this.staking.userStakeInfo(this.alice.address);
			await expect(info2[0].length).to.eq(1);
			await expect(info2[1]).to.gt(BigNumber.from("0"));
    });

    it("should get user stake information", async function () {
			await this.staking.stake([1]);
			await time.increase(SECONDS_IN_DAY);

			const stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("5555555555555555555555"));
    });

		it("should be correct rewards in period 1", async function () {
			await this.staking.stake([1]);
			await time.increase(SECONDS_IN_DAY * 180);

			const stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("999999999999999999999900"));
    });

		it("should be correct rewards in period 2", async function () {
			await this.staking.stake([1]);
			await time.increase(SECONDS_IN_DAY * 180 * 2);

			const stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("1799999999999999999999820"));
    });

		it("should be correct rewards in period 3", async function () {
			await this.staking.stake([1]);
			await time.increase(SECONDS_IN_DAY * 180 * 3);

			const stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("2399999999999999999999760"));
    });

		it("should be correct rewards in period 4", async function () {
			await this.staking.stake([1]);
			await time.increase(SECONDS_IN_DAY * 180 * 4);

			const stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("2999999999999999999999700"));
    });

		it("total test", async function () {
			await time.increase(3600);
			await this.staking.stake([1]);

			await time.increase(SECONDS_IN_DAY);

			let stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("0"));

			await time.increase(SECONDS_IN_DAY);

			stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("5555555555555555555555"));

			await time.increase(SECONDS_IN_DAY);

			stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("11111111111111111111110"));

			await time.increase(3600);

			// Stake new token
			await this.staking.connect(this.alice).stake([3]);
			await expect(await this.staking.stakedTokenAmount()).to.eql(BigNumber.from(2));

			await time.increase(SECONDS_IN_DAY);

			// Rwards should NOT be divided.
			stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("16666666666666666666665"));

			stakeInfo = await this.staking.userStakeInfo(this.alice.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("0"));

			await time.increase(SECONDS_IN_DAY);

			// Rwards should be divided.
			stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("19444444444444444444442"));

			stakeInfo = await this.staking.userStakeInfo(this.alice.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("2777777777777777777777"));

			await time.increase(SECONDS_IN_DAY * 10);

			// Rwards should be divided.
			stakeInfo = await this.staking.userStakeInfo(this.deployer.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("47222222222222222222212"));

			stakeInfo = await this.staking.userStakeInfo(this.alice.address);
			await expect(stakeInfo[0].length).to.eq(1);
			await expect(stakeInfo[1]).to.eq(BigNumber.from("30555555555555555555547"));
    });*/
  });
});
