const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { ethers } = require("hardhat");

module.exports = buildModule("TimeLockMultiSigV2Module", (m) => {
  // Configuration for a 2-of-3 multisig wallet
  // Using proper checksummed addresses with ethers.getAddress()
  const owners = [
    ethers.getAddress("0x1dBFDd86CcE60423fd253c5A99aef842dBbA0a4A"), // Owner 1 - Your deployer address
    ethers.getAddress("0xf2B6458901a9e916C3BcDCE63B17468E78A3d8d2"), // Owner 2 - Replace with real address  
    ethers.getAddress("0x0b4AC6E7e2367610FE572d0E8cE1eCc520dA6799")  // Owner 3 - Replace with real address
  ];
  
  const threshold = 2; // 2-of-3 signatures required
  const timeLockDelay = 24 * 60 * 60; // 24 hours in seconds
  const dailyLimit = ethers.parseEther("10.0"); // 10 CELO daily limit
  const instantLimit = ethers.parseEther("1.0"); // 1 CELO instant execution limit
  
  const timeLockMultiSig = m.contract("TimeLockMultiSig", [
    owners,
    threshold,
    timeLockDelay,
    dailyLimit,
    instantLimit
  ]);

  return { timeLockMultiSig };
});
