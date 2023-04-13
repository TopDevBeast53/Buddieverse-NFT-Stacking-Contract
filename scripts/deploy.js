// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.

const path = require("path");

async function main() {
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  // ethers is available in the global scope
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const SeedToken = await ethers.getContractFactory("SeedToken");
  const seedToken = await SeedToken.deploy(deployer.address, deployer.address);
  await seedToken.deployed();

  console.log("SeedToken address:", seedToken.address);

  const NFTCollection = await ethers.getContractFactory("NFTCollection");
  const collection = await NFTCollection.deploy();
  await collection.deployed();

  console.log("NFTCollection address:", collection.address);

  const Staking = await ethers.getContractFactory("BudStaking");
  const staking = await Staking.deploy(collection.address, seedToken.address);
	await staking.deployed();

  console.log("Staking contract address:", staking.address);

  console.log("Mint Seed token to address", staking.address);
  await seedToken.mint(staking.address, 3000000);

  console.log("Set approval for deployer", staking.address);
  await collection.setApprovalForAll(staking.address, true);

  await collection.mint(deployer.address, 1);
	await collection.mint(deployer.address, 2);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
