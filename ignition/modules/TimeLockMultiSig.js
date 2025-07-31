const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("TimeLockMultiSigModule", (m) => {
  // Sample configuration for a 2-of-3 multisig wallet
  const owners = [
    "0x1234567890123456789012345678901234567890", // Replace with actual addresses
    "0x2345678901234567890123456789012345678901",
    "0x3456789012345678901234567890123456789012"
  ];
  
  const threshold = 2; // 2-of-3 signatures required
  const timeLockDelay = 24 * 60 * 60; // 24 hours in seconds
  const dailyLimit = m.parseEther("10.0"); // 10 CELO daily limit
  const instantLimit = m.parseEther("1.0"); // 1 CELO instant execution limit
  
  const timeLockMultiSig = m.contract("TimeLockMultiSig", [
    owners,
    threshold,
    timeLockDelay,
    dailyLimit,
    instantLimit
  ]);

  return { timeLockMultiSig };
});
