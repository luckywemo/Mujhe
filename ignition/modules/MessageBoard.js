const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("MessageBoardModule", (m) => {
  // Deploy the MessageBoard contract
  const messageBoard = m.contract("MessageBoard", []);

  return { messageBoard };
});
