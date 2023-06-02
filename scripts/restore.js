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

  const json = fs.readFileSync('migrateTokens.json');
  const migrateTokens = JSON.parse(json);
  console.log('migrateTokens', migrateTokens.length);

  const tokenIdList = migrateTokens.map(i => i.tokenId);
  console.log('tokenIdList', tokenIdList.length);

  const staking = new ethers.Contract("0x71A26224239bd0e7C16aA614B6d49FbFFD3De793", BUDSTAKING.abi, deployer);
  console.log("Staking address:", staking.address);

  // Send NFTs to old from new staking contract.
  for (let tokenId of tokenIdList) {
    console.log('Transfer NFT', tokenId);
    await collection.transferFrom(staking.address, oldStaking.address, tokenId);
  }
  console.log('NFTs have been transfered to new staking contract');

  await oldStaking.unpause();
  console.log("Staking is unpaused");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//npx hardhat run scripts/restore.js --network exosama
