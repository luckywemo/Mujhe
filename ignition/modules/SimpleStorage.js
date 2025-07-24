const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("SimpleStorageModule", (m) => {
  // Deploy the SimpleStorage contract
  const simpleStorage = m.contract("SimpleStorage");

  return { simpleStorage };
});
