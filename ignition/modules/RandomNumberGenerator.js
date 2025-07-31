const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("RandomNumberGeneratorModule", (m) => {
  // Deploy the RandomNumberGenerator contract
  const randomNumberGenerator = m.contract("RandomNumberGenerator", []);

  return { randomNumberGenerator };
});
