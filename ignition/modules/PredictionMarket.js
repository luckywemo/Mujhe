const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const INITIAL_FEE_BPS = 100; // 1% platform fee (100 basis points)

module.exports = buildModule("PredictionMarketModule", (m) => {
  // Get the deployer's account to set as the initial owner.
  const initialOwner = m.getAccount(0);

  // The constructor requires the initial owner and the initial platform fee.
  const predictionMarket = m.contract("PredictionMarket", [
    initialOwner,
    INITIAL_FEE_BPS,
  ]);

  return { predictionMarket };
});
