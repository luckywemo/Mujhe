const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("TodoListModule", (m) => {
  // Deploy the TodoList contract
  const todoList = m.contract("TodoList");

  return { todoList };
});
