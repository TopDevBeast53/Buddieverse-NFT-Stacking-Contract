// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.

const CONTRACT_NFT_COLLECTION = "0xbaf909886c0a0cc195fd36ea24f21f93abc23c2c";

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

  const collection = CONTRACT_NFT_COLLECTION;
  console.log("NFTCollection address:", collection);

  const SeedToken = await ethers.getContractFactory("SeedToken");
  const seedToken = await SeedToken.deploy(deployer.address, deployer.address);
  await seedToken.deployed();
  console.log("SeedToken address:", seedToken.address);

  const Staking = await ethers.getContractFactory("BudStaking");
  const staking = await Staking.deploy(collection, seedToken.address);
	await staking.deployed();
  console.log("Staking contract address:", staking.address);

  console.log("Mint Seed token to address", staking.address);
  const ethersToWei = ethers.utils.parseUnits("3000000", "ether");
  await seedToken.mint(staking.address, ethersToWei);

  const balance = await seedToken.balanceOf(staking.address);
  console.log("Balance of seed token", balance);

  const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = await Marketplace.deploy(seedToken.address);
  await marketplace.deployed();
  console.log("Marketplace address:", marketplace.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//npx hardhat run scripts/deploy.js --network exosama
