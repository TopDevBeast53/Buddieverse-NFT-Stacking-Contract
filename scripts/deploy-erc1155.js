const BudItems = require("../artifacts/contracts/BudItems.sol/BudItems.json");
const CONTRACT_BUD_ITEMS = '0xd041dCCf76BEAF6487F0286F88BDA5307FC0310c';

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

  // Init deploy
  const uri = "https://ipfs.io/ipfs/QmQYB5pQDN9zsJQ5PAL4Tc9zWtYpnoKfhb2puM7HCAVGQL/{id}.json";

  const BudItems = await ethers.getContractFactory("BudItems");
  const budItems = await BudItems.deploy(uri);
  await budItems.deployed();
  console.log("BudItems address:", budItems.address);

  const mint = await budItems.mintBatch(deployer.address, [1], [5], '0x00');
  console.log("BudItems mint:", mint);

  /*const budItems = new ethers.Contract(CONTRACT_BUD_ITEMS, BudItems.abi, deployer);
  console.log("BudItems address:", budItems.address);

  const mint = await budItems.mintBatch(deployer.address, [1], [2], '0x00');
  console.log("BudItems mint:", mint);*/
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//npx hardhat run scripts/deploy-erc1155.js --network exosama
