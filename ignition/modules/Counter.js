const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("CounterModule", (m) => {
  // Deploy the Counter contract
  const counter = m.contract("Counter");

  return { counter };
});
