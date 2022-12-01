const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const TestToken = await hre.ethers.getContractFactory("TestToken");
  const testToken = await TestToken.deploy();
  
  await testToken.deployed();
  
  console.log("TestToken deployed to:", testToken.address);

  const  LpToken = await hre.ethers.getContractFactory("LpToken");
  const lpToken = await LpToken.deploy();
  
  await lpToken.deployed();
  
  console.log("LpToken deployed to:", lpToken.address);

  const _myadress = "0x3769C1F158DB28A5a098C00ACC8EE6cdF91B27E3";
  const _tokenPerBlock = 5;
  const _startBlock = 0

  const MasterFork = await hre.ethers.getContractFactory("MasterFork");
  const masterFork = await MasterFork.deploy(testToken.address, _myadress , _tokenPerBlock, _startBlock);

  await masterFork.deployed();

  console.log("MasterFork deployed to:", masterFork.address);






}



// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});