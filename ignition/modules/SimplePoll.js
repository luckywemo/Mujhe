const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const POLL_QUESTION = "Is building on CELO a good experience?";

module.exports = buildModule("SimplePollModule", (m) => {
  const poll = m.contract("SimplePoll", [POLL_QUESTION]);

  return { poll };
});
