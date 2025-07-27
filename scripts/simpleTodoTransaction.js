async function main() {
  const { ethers } = require("hardhat");
  
  console.log("🎯 Creating your third task on TodoList!");
  
  // Contract address
  const todoListAddress = "0xD50fCE5736019dB84f7033Ab18Aa36064035625c";
  
  // Priority enum
  const Priority = { LOW: 0, MEDIUM: 1, HIGH: 2, URGENT: 3 };
  
  // Get contract
  const TodoList = await ethers.getContractFactory("TodoList");
  const todoList = TodoList.attach(todoListAddress);
  const [signer] = await ethers.getSigners();
  
  console.log("Contract:", todoListAddress);
  console.log("Your address:", signer.address);
  
  // Check CELO balance
  const balance = await ethers.provider.getBalance(signer.address);
  console.log("CELO balance:", ethers.formatEther(balance));
  
  try {
    // Create your third task
    const title = "Learn CELO blockchain development 3";
    const description = "Complete CELO smart contract tutorial and deploy contracts";
    const priority = Priority.HIGH;
    const dueDate = Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60); // 1 week
    
    console.log("Creating task:", title);
    console.log("Priority: HIGH");
    
    const tx = await todoList.createTask(title, description, priority, dueDate);
    console.log("TX Hash:", tx.hash);
    
    const receipt = await tx.wait();
    console.log("✅ Success! Block:", receipt.blockNumber);
    console.log("Gas used:", receipt.gasUsed.toString());
    
    // Get task count
    const taskCount = await todoList.userTaskCount(signer.address);
    console.log("Your task count:", taskCount.toString());
    
    // Get your tasks
    const yourTasks = await todoList.getUserTasks(signer.address);
    console.log("Your task IDs:", yourTasks.map(id => id.toString()).join(", "));
    
    // Get the first task details
    if (yourTasks.length > 0) {
      const [id, taskTitle, taskDesc, taskPriority, status] = await todoList.getTask(yourTasks[0]);
      console.log("Task details:");
      console.log("- ID:", id.toString());
      console.log("- Title:", taskTitle);
      console.log("- Priority:", taskPriority.toString());
      console.log("- Status:", status.toString());
    }
    
    console.log("🔍 View on CeloScan:");
    console.log(`https://celoscan.io/tx/${tx.hash}`);
    
  } catch (error) {
    console.error("Error:", error.message);
  }
}

main().catch(console.error);
