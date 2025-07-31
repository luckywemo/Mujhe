const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("VotingSystemModule", (m) => {
  // Deploy the VotingSystem contract
  const votingSystem = m.contract("VotingSystem");

  return { votingSystem };
});
