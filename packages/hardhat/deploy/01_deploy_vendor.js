// deploy/01_deploy_vendor.js

const { ethers } = require("hardhat");

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  // You might need the previously deployed yourToken:
  const yourToken = await ethers.getContract("YourToken", deployer);

  // Todo: deploy the vendor
  await deploy("Vendor", {
    from: deployer,
    args: [yourToken.address], // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    log: true,
  });
  //
  const vendor = await ethers.getContract("Vendor", deployer);

  // Todo: transfer the tokens to the vendor
  console.log("\n 🏵  Sending all 1000 tokens to the vendor...\n");
  //
  const transferTransaction = await yourToken.transfer(
    vendor.address,
    ethers.utils.parseEther("1000")
  );

  const transferResult = await transferTransaction.wait();
  console.log(
    `Transfer transaction executed successfully in block: ${transferResult.blockNumber}`
  );

  console.log("\n    ✅ confirming...\n");
  await sleep(5000); // wait 5 seconds for transaction to propagate

  // ToDo: change address to your frontend address vvvv
  console.log("\n 🤹  Sending ownership to frontend address...\n");
  const ownershipTransaction = await vendor.transferOwnership(
    "0x61a66Cc7D0B341cC55D5EB426f78697daf0B192B"
  );
  console.log("\n    ✅ confirming...\n");
  const ownershipResult = await ownershipTransaction.wait();

  console.log(
    `Transfer ownership transaction executed successfully in block: ${ownershipResult.blockNumber}`
  );

  // ToDo: Verify your contract with Etherscan for public chains
  if (chainId !== "31337") {
    try {
      console.log(" 🎫 Verifing Contract on Etherscan... ");
      await sleep(5000); // wait 5 seconds for deployment to propagate
      await run("verify:verify", {
        address: vendor.address,
        contract: "contracts/Vendor.sol:Vendor",
        constructorArguments: [yourToken.address],
      });
    } catch (e) {
      console.log(" ⚠️ Failed to verify contract on Etherscan ");
    }
  }
};

module.exports.tags = ["Vendor"];
