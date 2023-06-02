const SeedToken = require("../artifacts/contracts/SeedToken.sol/SeedToken.json");
const CONTRACT_SEEDS_ADDRESS = '0xe78D317c5db782aCF8F100e8A67E2c77daC3e270';

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

  const seedToken = new ethers.Contract(CONTRACT_SEEDS_ADDRESS, SeedToken.abi, deployer);
  console.log("SeedToken address:", seedToken.address);

  const to = "0xDFE055245aB0b67fB0B5AE3EA28CD1fee40299df";
  const ethersToWei = ethers.utils.parseUnits("10000", "ether");
  await seedToken.mint(to, ethersToWei);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//npx hardhat run scripts/airdrop-seeds.js --network exosama
