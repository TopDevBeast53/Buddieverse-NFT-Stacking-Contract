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

  // {
  //   const to = "0xDFE055245aB0b67fB0B5AE3EA28CD1fee40299df";
  //   await collection.mint(to, 14);
	//   await collection.mint(to, 15);
	//   await collection.mint(to, 16);
  // }
  // {
  //   const to = "0x932baD9228d2BB187548677ce6712f9b001993a9";
  //   await collection.mint(to, 17);
	//   await collection.mint(to, 18);
	//   await collection.mint(to, 19);
  // }
  {
    const to = "0xebd9A48eD1128375EB4383ED4d53478B4FD85a8D";
    // await collection.mint(to, 20);
	  await collection.mint(to, 21);
	  await collection.mint(to, 22);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


  //npx hardhat run scripts/deploy-mint-collection.js --network bsc