// deploy/00_deploy_example_external_contract.js

const { ethers } = require("hardhat");

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer, contractOwner, admin, issuer } = await getNamedAccounts();

  const fixedSupply = "0x19d971e4fe8402000000000"; // 500 Million ETV Tokens
  const transferThreshold = "0x43c33c1937564800000"; // 20K ETV for IssueETV Contract

  console.log(
    `admin & issuer & transferThreshold & fixedSupply are: \n${admin}\n${issuer}\n${transferThreshold}\n${fixedSupply}`
  );

  const chainId = await getChainId();

  console.log(`Chain Id: ${chainId}`);

  /**
   * `deploy` returns an object having the below keys.
   * [
        'address',         'abi',
        'transactionHash', 'receipt',
        'args',            'numDeployments',
        'solcInputHash',   'metadata',
        'bytecode',        'deployedBytecode',
        'devdoc',          'userdoc',
        'storageLayout',   'newlyDeployed'
      ]
   */

  /* const earnTVContract = await deploy("EarnTV", {
    from: deployer,
    args: [fixedSupply, contractOwner, [admin]],
    log: true,
  });

  console.log(`EarnTV contract is deployed at ${earnTVContract.address}`);
  */

  const earnTVContract = await ethers.getContractAt(
    "EarnTV",
    "0x7614454ed4b76921DfB4a3918963b4E9460574Bb"
  );
  console.log(`EarnTV contract is deployed at ${earnTVContract.address}`);

  await sleep(5000); // wait 5 seconds for transaction to propagate

  const rewardContract = await ethers.getContractAt(
    "Reward",
    "0x6c2856BA45057f3E28901658D31aCf127b3f38a0"
  );

  console.log(`Reward contract is deployed at ${rewardContract.address}`);

  await sleep(5000); // wait 5 seconds for transaction to propagate

  const stakeContract = await deploy("StakeETV", {
    from: deployer,
    args: [rewardContract.address, earnTVContract.address],
    log: true,
  });

  console.log(`Stake contract is deployed at ${stakeContract.address}`);

  await sleep(5000); // wait 5 seconds for transaction to propagate

  /**
   * This is how you create a contract instance inside hardhat-deploy
   */
  const rewardConInstance = await ethers.getContractAt(
    "Reward",
    "0x6c2856BA45057f3E28901658D31aCf127b3f38a0",
    deployer
  );

  // Transfer 1 Million RewardToken to StakeETV contract
  console.log("\n 🏵  Sending 5 Million rETV to StakeETV contract...\n");

  const transferTransaction = await rewardConInstance.transfer(
    stakeContract.address,
    ethers.utils.parseEther("5000000")
  );

  const transferResult = await transferTransaction.wait();
  console.log(
    `Transfer transaction executed successfully in block: ${transferResult.blockNumber}`
  );

  console.log("\n    ✅ confirming...\n");
  await sleep(5000); // wait 5 seconds for transaction to propagate

  console.log("\n    ✅ printing StakeETV rETV token balance...\n");
  const balance = await rewardConInstance.balanceOf(stakeContract.address);
  // eslint-disable-next-line no-underscore-dangle
  const decimalValue = ethers.BigNumber.from(balance._hex).toString();
  const value = ethers.utils.parseUnits(decimalValue, "ether");
  const formattedValue = ethers.utils.formatUnits(value, "ether", {
    commify: true,
  });
  console.log(`\n    ✅ Balance = ${formattedValue / 1e18}`);

  /*
  // Transfer 1 Million ETV to the front-end address
  const stakeConInstance = await ethers.getContract("StakeETV", contractOwner);

  // Transfer 1 Million ETV to front-end contract
  console.log("\n 🏵  Sending 1 Million ETV to front-end address...\n");

  await stakeConInstance.transfer(
    "0x78157C5Ca2e024D429A6b01E21caf542064a8De8", // NFT-Admin
    ethers.utils.parseEther("1000000")
  );
  */

  // Getting a previously deployed contract
  // const ExampleExternalContract = await ethers.getContract(
  //   "ExampleExternalContract",
  //   deployer
  // );

  // await YourContract.setPurpose("Hello");

  // if you want to instantiate a version of a contract at a specific address!
  // const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A")

  // If you want to send value to an address from the deployer
  // const deployerWallet = ethers.provider.getSigner()
  // await deployerWallet.sendTransaction({
  //   to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
  //   value: ethers.utils.parseEther("0.001")
  // })

  // If you want to send some ETH to a contract on deploy (make your constructor payable!)
  // const yourContract = await deploy("YourContract", [], {
  // value: ethers.utils.parseEther("0.05")
  // });

  // If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  // const yourContract = await deploy("YourContract", [], {}, {
  //  LibraryName: **LibraryAddress**
  // });

  // Verification;
  if (chainId !== "31337") {
    try {
      console.log(" 🎫 Verifing Contract on Etherscan... ");
      await sleep(5000); // wait 5 seconds for deployment to propagate
      await run("verify:verify", {
        address: stakeContract.address,
        contract: "contracts/StakeETV.sol:StakeETV",
        constructorArguments: [rewardContract.address, earnTVContract.address],
      });
      // await sleep(5000); // wait 5 seconds for deployment to propagate
      // await run("verify:verify", {
      //   address: rewardContract.address,
      //   contract: "contracts/Reward.sol:Reward",
      //   constructorArguments: [],
      // });
    } catch (error) {
      console.log("⚠️ Contract Verification Failed: ", error);
    }
  }
};

module.exports.tags = ["ExampleExternalContract"];
