const SeedToken = require("../artifacts/contracts/SeedToken.sol/SeedToken.json");
const CONTRACT_SEED_TOKEN = '0x27A419d11d622481ed8D7e620B0940497C93bc38';

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

  /*const SeedToken = await ethers.getContractFactory("SeedToken");
  const seedToken = await SeedToken.deploy(deployer.address, deployer.address);
  await seedToken.deployed();
  console.log("SeedToken address:", seedToken.address);*/

  const seedToken = new ethers.Contract(CONTRACT_SEED_TOKEN, SeedToken.abi, deployer);
  console.log("SeedToken address:", seedToken.address);

  const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = await Marketplace.deploy(seedToken.address);
  await marketplace.deployed();
  console.log("Marketplace address:", marketplace.address);

  // console.log("Mint Seed token to address");
  // const ethersToWei = ethers.utils.parseUnits("1000", "ether");
  // await seedToken.mint(deployer.address, ethersToWei);

  const balance = await seedToken.balanceOf(deployer.address);
  console.log("Balance of seed token", balance);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//npx hardhat run scripts/deploy-market.js --network exosama
