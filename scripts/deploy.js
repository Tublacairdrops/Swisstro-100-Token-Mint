const hre = require("hardhat");

async function main() {
  const contract = await hre.ethers.deployContract("TestToken");

  await contract.waitForDeployment();

  console.log(`Contract address : ${contract.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
