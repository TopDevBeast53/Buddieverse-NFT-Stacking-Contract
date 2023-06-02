const SEEDTOKEN = require("../artifacts/contracts/SeedToken.sol/SeedToken.json");
const MARKETPLACE = require("../artifacts/contracts/Marketplace.sol/Marketplace.json");

const CONTRACT_SEEDS_ADDRESS = '0xe78D317c5db782aCF8F100e8A67E2c77daC3e270';
const CONTRACT_MARKETPLACE = '0x445c715d0698c26Df81454258b1316900A7955EC';

const CONTRACT_MARKETPLACE_NEW = '0x95967bA4Fc6d6D4aD1Eea45eD5EC43128f0332A1';

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

  const seedToken = new ethers.Contract(CONTRACT_SEEDS_ADDRESS, SEEDTOKEN.abi, deployer);
  console.log("SeedToken address:", seedToken.address);

  const marketplace_old = new ethers.Contract(CONTRACT_MARKETPLACE, MARKETPLACE.abi, deployer);
  console.log("Old Marketplace address:", marketplace_old.address);

  // await marketplace_old.pause();
  // console.log('Marketplace is paused');

  /*const orders = [];
  for (let i = 0; i <= 13; i++) {
    const order = await marketplace_old.orderArray(i);
    orders.push(order);
  }
  console.log('orders', orders);*/

  /*const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = await Marketplace.deploy(seedToken.address);
  await marketplace.deployed();
  console.log("Marketplace address:", marketplace.address);*/
  const marketplace = new ethers.Contract(CONTRACT_MARKETPLACE_NEW, MARKETPLACE.abi, deployer);
  console.log("Marketplace address:", marketplace.address);

  const balance = await marketplace_old.provider.getBalance(marketplace_old.address);
  console.log('balance', balance);

  if (balance > 0) {
    console.log('Send Ether to new marketplace contract.')
    await deployer.sendTransaction({
      to: marketplace.address,
      value: balance,
    });
  }

  const tokenBalance = await seedToken.balanceOf(marketplace_old.address);
  if (tokenBalance > 0) {
    console.log('Send tokens to new marketplace contract.')
    await seedToken.transferFrom(marketplace_old.address, marketplace.address, tokenBalance);
  }

  console.log('Successfully migrated');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//npx hardhat run scripts/migrate-market.js --network exosama
