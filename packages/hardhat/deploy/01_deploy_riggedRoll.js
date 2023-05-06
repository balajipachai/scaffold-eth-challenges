const { ethers } = require("hardhat");

const localChainId = "31337";

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const diceGame = await ethers.getContract("DiceGame", deployer);

  await deploy("RiggedRoll", {
    from: deployer,
    args: [diceGame.address],
    log: true,
  });

  const riggedRoll = await ethers.getContract("RiggedRoll", deployer);

  const ownershipTransaction = await riggedRoll.transferOwnership(
    "0xbB56cFDD9d9ffd449f53a96457CbDCBDb003836E"
  );

  console.log(`Ownership transfer transaction: ${ownershipTransaction}`);

  await sleep(5000);

  const ownershipTransferResult = await ownershipTransaction.wait();
  console.log(
    `Ownership transfer mined in block ${ownershipTransferResult.blockNumber}`
  );
};

module.exports.tags = ["RiggedRoll"];
