const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("GreetingsModule", (m) => {
  // Deploy the Greetings contract
  const greetings = m.contract("Greetings");

  return { greetings };
});
