#!/bin/bash

print_blue() {
    echo -e "\033[34m$1\033[0m"
}

print_red() {
    echo -e "\033[31m$1\033[0m"
}

print_green() {
    echo -e "\033[32m$1\033[0m"
}

print_pink() {
    echo -e "\033[95m$1\033[0m"
}

prompt_for_input() {
    read -p "$1" input
    echo $input
}

print_blue "Installing Hardhat and necessary dependencies..."
echo
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
echo

print_blue "Removing default package.json file..."
echo
rm package.json
echo

print_blue "Creating package.json file again..."
echo
cat <<EOL > package.json
{
  "name": "hardhat-project",
  "devDependencies": {
    "@nomicfoundation/hardhat-toolbox": "^3.0.0",
    "hardhat": "^2.17.1"
  },
  "dependencies": {
    "@openzeppelin/contracts": "^4.9.3",
    "@swisstronik/utils": "^1.2.1"
  }
}
EOL

print_blue "Initializing Hardhat project..."
npx hardhat
echo
print_blue "Removing the default Hardhat configuration file..."
echo
rm hardhat.config.js
echo
read -p "Enter your wallet private key: " PRIVATE_KEY

if [[ $PRIVATE_KEY != 0x* ]]; then
  PRIVATE_KEY="0x$PRIVATE_KEY"
fi

cat <<EOL > hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.19",
  networks: {
    swisstronik: {
      url: "https://json-rpc.testnet.swisstronik.com/",
      accounts: ["$PRIVATE_KEY"],
    },
  },
};
EOL

print_blue "Hardhat configuration file has been updated."
echo

rm -f contracts/Lock.sol
sleep 2

echo
print_pink "Enter TOKEN NAME:"
read -p "" TOKEN_NAME
echo
print_pink "Enter TOKEN SYMBOL:"
read -p "" TOKEN_SYMBOL
echo
cat <<EOL > contracts/Token.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor()ERC20("$TOKEN_NAME","$TOKEN_SYMBOL"){} 

    function mint100tokens() public {
        _mint(msg.sender,100*10**18);
    }

    function burn100tokens() public{
        _burn(msg.sender,100*10**18);
    }
    
}
EOL
echo

npm install
echo
print_blue "Compiling the contract..."
echo
npx hardhat compile
echo

print_blue "Creating scripts directory and the deployment script..."
echo

mkdir -p scripts

cat <<EOL > scripts/deploy.js
const hre = require("hardhat");

async function main() {
  const contract = await hre.ethers.deployContract("TestToken");

  await contract.waitForDeployment();

  console.log(\`Contract address : \${contract.target}\`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOL
echo

npx hardhat run scripts/deploy.js --network swisstronik
echo

print_green "Contract deployment successful, Copy the above contract address and save it somewhere, you need to submit it in Testnet website"
echo
print_blue "Creating mint.js file..."
echo
read -p "Enter yours Token Contract Address: " CONTRACT_ADDRESS
echo
cat <<EOL > scripts/mint.js
const hre = require("hardhat");
const { encryptDataField, decryptNodeResponse } = require("@swisstronik/utils");
const sendShieldedTransaction = async (signer, destination, data, value) => {
  const rpcLink = hre.network.config.url;
  const [encryptedData] = await encryptDataField(rpcLink, data);
  return await signer.sendTransaction({
    from: signer.address,
    to: destination,
    data: encryptedData,
    value,
  });
};

async function main() {
  const contractAddress = "$CONTRACT_ADDRESS";
  const [signer] = await hre.ethers.getSigners();

  const contractFactory = await hre.ethers.getContractFactory("TestToken");
  const contract = contractFactory.attach(contractAddress);

  const functionName = "mint100tokens";
  const mint100TokensTx = await sendShieldedTransaction(
    signer,
    contractAddress,
    contract.interface.encodeFunctionData(functionName),
    0
  );

  await mint100TokensTx.wait();

  console.log("Transaction Receipt: ", mint100TokensTx.hash);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOL

cat <<EOL > scripts/transfer.js
const hre = require("hardhat");
const { encryptDataField, decryptNodeResponse } = require("@swisstronik/utils");
const sendShieldedTransaction = async (signer, destination, data, value) => {
  const rpcLink = hre.network.config.url;
  const [encryptedData] = await encryptDataField(rpcLink, data);
  return await signer.sendTransaction({
    from: signer.address,
    to: destination,
    data: encryptedData,
    value,
  });
};

async function main() {
  const replace_contractAddress = "$CONTRACT_ADDRESS";
  const [signer] = await hre.ethers.getSigners();

  const replace_contractFactory = await hre.ethers.getContractFactory("TestToken");
  const contract = replace_contractFactory.attach(replace_contractAddress);

  const replace_functionName = "transfer";
  const replace_functionArgs = ["0x16af037878a6cAce2Ea29d39A3757aC2F6F7aac1", "1"];
  const transaction = await sendShieldedTransaction(signer, replace_contractAddress, contract.interface.encodeFunctionData(replace_functionName, replace_functionArgs), 0);

  await transaction.wait();
  console.log("Transfer Transaction Hash:", \`https://explorer-evm.testnet.swisstronik.com/tx/\${transaction.hash}\`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOL

print_blue "Minting $TOKEN_SYMBOL..."
npx hardhat run scripts/mint.js --network swisstronik
echo
print_blue "Transferring $TOKEN_SYMBOL..."
npx hardhat run scripts/transfer.js --network swisstronik
echo
print_green "Copy the above Tx URL and save it somewhere, you need to submit it on Testnet page"
echo
sed -i 's/0x[0-9a-fA-F]*,\?\s*//g' hardhat.config.js
echo
print_blue "PRIVATE_KEY has been removed from hardhat.config.js."
echo
print_blue "Pushing these files to your github Repo link"
git add . && git commit -m "Initial commit" && git push origin main
echo
print_pink "Follow @ZunXBT on X for more one click guide like this"
echo
