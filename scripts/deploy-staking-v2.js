const SeedToken = require("../artifacts/contracts/SeedToken.sol/SeedToken.json");
const NFTCollection = require("../artifacts/contracts/NFTCollection.sol/NFTCollection.json");

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

  const Staking = await ethers.getContractFactory("BudStaking");
  const staking = await Staking.deploy(collection.address, seedToken.address);
	await staking.deployed();
  console.log("Staking contract address:", staking.address);

  const seedToken = new ethers.Contract("0xedEdF53A59625755De62074C2d222B1d9914d6f0", SeedToken.abi, deployer);
  console.log("SeedToken address:", seedToken.address);

  const from = "0xAAf9E0613910916f55c0d648F26127b6901Ce471";
  const balance = await seedToken.balanceOf(from);
  console.log("Balance of seed tokens", balance)
  
  console.log("Send seed tokens to new staking contract");
  await seedToken.transferFrom(from, staking.address, balance);
  
  const collection = new ethers.Contract("0x96FCB2984F43f652E4430763a7e5Bb76146F5371", NFTCollection.abi, deployer);
  console.log("NFTCollection address:", collection.address);

  console.log("Set approval for deployer", staking.address);
  await collection.setApprovalForAll(staking.address, true);

  await collection.mint(deployer.address, 1);
	await collection.mint(deployer.address, 2);
	await collection.mint(deployer.address, 3);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });



//npx hardhat run scripts/deploy-staking-v2.js --network bsc