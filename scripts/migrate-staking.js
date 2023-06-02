const fs = require('fs');

const BUDSTAKING = require("../artifacts/contracts/BudStaking.sol/BudStaking.json");
const NFTCOLLECTION = require("../artifacts/contracts/NFTCollection.sol/NFTCollection.json");

const CONTRACT_STAKING_ADDRESS = '0xABd266B810f559c0858d56378b52730F0C53101c';
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

  const collection = new ethers.Contract(CONTRACT_NFT_COLLECTION, NFTCOLLECTION.abi, deployer);
  console.log("NFTCollection address:", collection.address);

  const oldStaking = new ethers.Contract(CONTRACT_STAKING_ADDRESS, BUDSTAKING.abi, deployer);
  console.log("Old staking address:", oldStaking.address);

  const startTime = await oldStaking.startTime();
  console.log('startTime', startTime);

  /*const length = 102;
  const migrateTokens = [];

  for (let i = 0; i <= length; i++) {
    const staker = await oldStaking.stakersArray(i);
    console.log('staker', i, staker);

    const stakeInfo = await oldStaking.userStakeInfo(staker);

    const tokens = stakeInfo._stakedTokens.map(token => {
      return {
        tokenId: token.tokenId,
        timestamp: token.timestamp,
        owner: staker,
      }
    });

    migrateTokens.push(...tokens);
  }

  console.log('migrateTokens', migrateTokens);
  fs.writeFileSync('migrateTokens.json', JSON.stringify(migrateTokens));*/

  const json = fs.readFileSync('migrateTokens.json');
  const migrateTokens = JSON.parse(json);
  console.log('migrateTokens', migrateTokens.length);

  const tokenIdList = migrateTokens.map(i => i.tokenId);
  console.log('tokenIdList', tokenIdList.length);

  const SeedToken = await ethers.getContractFactory("SeedToken");
  const seedToken = await SeedToken.deploy(deployer.address, deployer.address);
  await seedToken.deployed();
  console.log("SeedToken address:", seedToken.address);

  const Staking = await ethers.getContractFactory("BudStaking");
  const staking = await Staking.deploy(collection.address, seedToken.address);
	await staking.deployed();
  console.log("Staking contract address:", staking.address);

  console.log("Mint Seed token to address", staking.address);
  const ethersToWei = ethers.utils.parseUnits("3000000", "ether");
  await seedToken.mint(staking.address, ethersToWei);

  console.log('Update start time');
  await staking.setStartTime(startTime);

  console.log('Add staked tokens to new contract');
  for (let i = 0; i < Math.floor(1 + (migrateTokens.length / 30)); i++) {
    const startIndex = i * 30;
    const endIndex = (i + 1) * 30;
    console.log("Add staked tokens", startIndex, endIndex);
    const tokens = migrateTokens.slice(startIndex, endIndex);
    await staking.addStakedTokens(tokens);    
  }
  console.log('Staking token migrated');

  // Send NFTs to new staking contract.
  for (let tokenId of tokenIdList) {
    console.log('Transfer NFT', tokenId);
    await collection.transferFrom(oldStaking.address, staking.address, tokenId);
  }
  console.log('NFTs have been transfered to new staking contract');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//npx hardhat run scripts/migrate-staking.js --network exosama
