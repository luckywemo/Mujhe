const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("SimpleTokenModule", (m) => {
  // Deploy the SimpleToken contract
  const simpleToken = m.contract("SimpleToken");

  return { simpleToken };
});
