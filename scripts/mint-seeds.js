const SeedToken = require("../artifacts/contracts/SeedToken.sol/SeedToken.json");
const CONTRACT_SEED_TOKEN = '0xe78D317c5db782aCF8F100e8A67E2c77daC3e270';

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

  const seedToken = new ethers.Contract(CONTRACT_SEED_TOKEN, SeedToken.abi, deployer);
  console.log("SeedToken address:", seedToken.address);

  const totalSupply = await seedToken.totalSupply();
  console.log("TotalSupply", totalSupply);

  const maxSupply = ethers.utils.parseUnits("10000000", "ether");
  console.log("MaxSupply", maxSupply);

  const numOfTokens = maxSupply.sub(totalSupply);
  console.log("NumOfTokens", numOfTokens);

  const to = "0x55A939CCA5e819AB350e14192E0a075a98b4FE31";
  await seedToken.mint(to, numOfTokens);

  // const mintTokens = ethers.utils.parseUnits("3000000", "ether");
  // const to = "0x55A939CCA5e819AB350e14192E0a075a98b4FE31";
  // await seedToken.mint(to, mintTokens);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  //npx hardhat run scripts/mint-seeds.js --network exosama
