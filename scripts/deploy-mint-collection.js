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

  const collection = new ethers.Contract("0x96FCB2984F43f652E4430763a7e5Bb76146F5371", NFTCollection.abi, deployer);
  console.log("NFTCollection address:", collection.address);

  const to = "0xDFE055245aB0b67fB0B5AE3EA28CD1fee40299df";
  await collection.mint(to, 3);
	await collection.mint(to, 4);
	await collection.mint(to, 5);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
