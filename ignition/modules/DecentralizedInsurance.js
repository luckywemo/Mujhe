const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("DecentralizedInsuranceModule", (m) => {
  // Deploy the DecentralizedInsurance contract
  const decentralizedInsurance = m.contract("DecentralizedInsurance", []);

  return { decentralizedInsurance };
});
