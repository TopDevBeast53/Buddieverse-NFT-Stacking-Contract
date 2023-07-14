const BUDSTAKING = require("../artifacts/contracts/BudStaking.sol/BudStaking.json");
const NFTCOLLECTION = require("../artifacts/contracts/NFTCollection.sol/NFTCollection.json");

const CONTRACT_STAKING_ADDRESS = '0xABd266B810f559c0858d56378b52730F0C53101c';
const CONTRACT_NFT_COLLECTION = '0xbaf909886c0a0cc195fd36ea24f21f93abc23c2c';

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

  const staking = new ethers.Contract(CONTRACT_STAKING_ADDRESS, BUDSTAKING.abi, deployer);
  console.log("Staking address:", staking.address);

  const collection = new ethers.Contract(CONTRACT_NFT_COLLECTION, NFTCOLLECTION.abi, deployer);
  console.log("Collection:", collection.address);

  // const tokenId = 86;//88;//87;//420//89;
  // console.log('TokenId', tokenId);
  // const address = '0xDF29B31798a447956E6fcef6CD9428c4ae9caF39';

  /*const tokens = await staking.userStakeInfo(address);
  console.log('tokens', tokens);*/

  // await collection.transferFrom(staking.address, address, tokenId);
  // console.log('Transfered', tokenId);
}

//0xDF29B31798a447956E6fcef6CD9428c4ae9caF39

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//npx hardhat run scripts/staking-checker.js --network exosama
