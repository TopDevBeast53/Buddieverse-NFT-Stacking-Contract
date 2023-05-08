const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { BigNumber } = ethers;

const formatEther = (value, precision = 4) => {
  const ethValue = ethers.utils.formatEther(value);
  const factor = Math.pow(10, precision);
  return (Math.floor(ethValue * factor) / factor).toString();
};

describe("SeedToken contract", function () {
  before(async function () {
    const SeedToken = await ethers.getContractFactory("SeedToken");

    this.signers = await ethers.getSigners();
    this.deployer = this.signers[0];
    this.alice = this.signers[1];
    this.bunner = this.signers[2];
    this.bob = this.signers[3];

    const unitPrice = ethers.utils.parseUnits("1000", "ether");

    this.seedToken = await SeedToken.deploy(
      this.deployer.address,
      this.deployer.address,
      unitPrice,
    );
    await this.seedToken.deployed();
  });

  // You can nest describe calls to create subsections.
  describe("Mint", function () {
    it("Admin should be able to mint", async function () {
      const ethersToWei = ethers.utils.parseUnits("3000", "ether");
      await this.seedToken.mint(this.deployer.address, ethersToWei);

      const balance = await this.seedToken.balanceOf(this.deployer.address);
      await expect(formatEther(balance)).to.eql("3000");
    });

    it("Alice should not be able to mint", async function () {
      const ethersToWei = ethers.utils.parseUnits("1000", "ether");
      await expect(
        this.seedToken.connect(this.alice).mint(this.alice.address, ethersToWei)
      ).to.be.revertedWith("Caller is not a minter");
    });
  });

  describe("Buy SEED", function () {
    it("Invalid cost", async function () {
      const ethersToWei = ethers.utils.parseUnits("10", "ether");
      await this.seedToken.setUnitPrice(ethersToWei);

      const cost = ethers.utils.parseUnits("0", "ether");
      const amount = ethers.utils.parseUnits("5", "ether");
      await expect(
        this.seedToken.connect(this.alice).buy(this.alice.address, amount, { value: cost })
      ).to.be.revertedWith("Invalid cost");
    });

    it("Cost is insufficient", async function () {
      const ethersToWei = ethers.utils.parseUnits("10", "ether");
      await this.seedToken.setUnitPrice(ethersToWei);

      const cost = ethers.utils.parseUnits("40", "ether");
      const amount = ethers.utils.parseUnits("5", "ether");
      await expect(
        this.seedToken.connect(this.alice).buy(this.alice.address, amount, { value: cost })
      ).to.be.revertedWith("Cost is insufficient");
    });

    it("Buy should be successed", async function () {
      const ethersToWei = ethers.utils.parseUnits("1.2", "ether");
      await this.seedToken.setUnitPrice(ethersToWei);

      const cost = ethers.utils.parseUnits("120", "ether");
      const amount = ethers.utils.parseUnits("100", "ether");
      await this.seedToken.connect(this.alice).buy(this.alice.address, amount, { value: cost });

      const balance = await this.seedToken.balanceOf(this.alice.address);
      await expect(formatEther(balance)).to.eql("100");
    });

    it("should be withdraw", async function () {
      const old = await this.seedToken.getBalance();
      await expect(formatEther(old)).to.eql("120");

      const amount = ethers.utils.parseUnits("120", "ether");
      await this.seedToken.withdraw(this.deployer.address, amount);

      const balance = await this.seedToken.getBalance();
      await expect(formatEther(balance)).to.eql("0");
    });
  });
});


100000000000000000000