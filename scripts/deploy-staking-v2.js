const SeedToken = require("../artifacts/contracts/SeedToken.sol/SeedToken.json");
const NFTCollection = require("../artifacts/contracts/NFTCollection.sol/NFTCollection.json");
const BudStaking = require("../artifacts/contracts/BudStaking.sol/BudStaking.json");
const { BigNumber } = require("ethers");

const CONTRACT_SEED_TOKEN = "0xedEdF53A59625755De62074C2d222B1d9914d6f0";
const CONTRACT_NFT_COLLECTION = "0x96FCB2984F43f652E4430763a7e5Bb76146F5371";

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

  const collection = new ethers.Contract(CONTRACT_NFT_COLLECTION, NFTCollection.abi, deployer);
  console.log("NFTCollection address:", collection.address);

  const Staking = await ethers.getContractFactory("BudStaking");
  const staking = await Staking.deploy(collection.address, seedToken.address);
	await staking.deployed();
  console.log("Staking contract address:", staking.address);

  console.log("Mint Seed token to address", staking.address);
  const ethersToWei = ethers.utils.parseUnits("3000000", "ether");
  await seedToken.mint(staking.address, ethersToWei);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });



//npx hardhat run scripts/deploy-staking-v2.js --network bsc