const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("TipJarModule", (m) => {
  // The contract's constructor requires the initial owner's address.
  // We get the deployer's account (the first account) to set as the owner.
  const initialOwner = m.getAccount(0);

  // Deploy the TipJar contract, passing the owner's address to the constructor.
  const tipJar = m.contract("TipJar", [initialOwner]);

  return { tipJar };
});
