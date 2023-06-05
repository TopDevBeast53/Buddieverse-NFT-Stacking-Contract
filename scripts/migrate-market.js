const SEEDTOKEN = require("../artifacts/contracts/SeedToken.sol/SeedToken.json");
const MARKETPLACE = require("../artifacts/contracts/Marketplace.sol/Marketplace.json");

const CONTRACT_SEEDS_ADDRESS = '0xe78D317c5db782aCF8F100e8A67E2c77daC3e270';

const CONTRACT_MARKETPLACE_OLD = '0x445c715d0698c26Df81454258b1316900A7955EC'; //Current Version
//const CONTRACT_MARKETPLACE_OLD = '0x5Cefe2172cF1A5d0fCB3d190933392Ac8b78e1aC';
//const CONTRACT_MARKETPLACE_OLD = '0x4d79b62166D970446FBe92Ea66b2ceCd44638b6A';
// const CONTRACT_MARKETPLACE_OLD = '0xfCD0C83D8Da0Fcaa1134eD07D6F6D223C84eAeb2';
//const CONTRACT_MARKETPLACE_OLD = '0xc9CbfAD7fb37D5fBD9F0427E9f74CE0DBEF9D344';

//const CONTRACT_MARKETPLACE_NEW = '0x4d79b62166D970446FBe92Ea66b2ceCd44638b6A';
//const CONTRACT_MARKETPLACE_NEW = '0xfCD0C83D8Da0Fcaa1134eD07D6F6D223C84eAeb2';
//const CONTRACT_MARKETPLACE_NEW = '0xc9CbfAD7fb37D5fBD9F0427E9f74CE0DBEF9D344';
const CONTRACT_MARKETPLACE_NEW = '0x1007062B070b92C8DbF4A44AFE097c272FC77A73';

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

  const marketplace_old = new ethers.Contract(CONTRACT_MARKETPLACE_OLD, MARKETPLACE.abi, deployer);
  console.log("Old Marketplace address:", marketplace_old.address);

  // await marketplace_old.pause();
  // console.log('Marketplace is paused');

  // const Marketplace = await ethers.getContractFactory("Marketplace");
  // const marketplace = await Marketplace.deploy(seedToken.address);
  // await marketplace.deployed();
  // console.log("New Marketplace address:", marketplace.address);
  // return;

  if (true) {
    const marketplace = new ethers.Contract(CONTRACT_MARKETPLACE_NEW, MARKETPLACE.abi, deployer);
    console.log("New Marketplace address:", marketplace.address);

    // const tokenBalance = await seedToken.balanceOf(marketplace_old.address);
    // console.log('tokenBalance', tokenBalance);
    // if (tokenBalance > 0) {
    //   console.log('Send tokens to new marketplace contract.')
    //   await seedToken.transferFrom(marketplace_old.address, marketplace.address, tokenBalance);
    // }

    // console.log("Migrate....");
    // await marketplace_old.migrate(deployer.address);

    const balance = await marketplace_old.provider.getBalance(marketplace_old.address);
    console.log('balance', balance);
    
    // Add order list to new contract.
    const orders = [];
    for (let i = 0; i <= 12; i++) {
      const order = await marketplace_old.orderArray(i);
      orders.push(order);
    }
    console.log('orders', orders.length);
    await marketplace.addOrders(orders, { value: balance });

    /*const orders = [];
    for (let i = 0; i <= 12; i++) {
      const order = await marketplace.orderArray(i);
      orders.push(order);
    }
    console.log('orders', orders.length);*/

    // const orders = await marketplace.getOrderArray();
    // console.log('orders', orders.length);
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
