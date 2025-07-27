async function main() {
  const { ethers } = require("hardhat");
  
  console.log("🎯 Creating your first tasks on the TodoList contract!");
  console.log("=" * 60);
  
  // Your deployed TodoList contract address
  const todoListAddress = "0xD50fCE5736019dB84f7033Ab18Aa36064035625c";
  
  // Priority and Status enums
  const Priority = { LOW: 0, MEDIUM: 1, HIGH: 2, URGENT: 3 };
  const Status = { PENDING: 0, IN_PROGRESS: 1, COMPLETED: 2, CANCELLED: 3 };
  
  // Get contract and signer
  const TodoList = await ethers.getContractFactory("TodoList");
  const todoList = TodoList.attach(todoListAddress);
  const [signer] = await ethers.getSigners();
  
  console.log("📍 Contract Address:", todoListAddress);
  console.log("👤 Your Address:", signer.address);
  
  // Check CELO balance
  const balance = await ethers.provider.getBalance(signer.address);
  console.log("💰 CELO Balance:", ethers.formatEther(balance));
  
  try {
    // Check current contract state
    console.log("\n📊 Current Contract State:");
    const totalTasks = await todoList.totalTasks();
    const userTaskCount = await todoList.userTaskCount(signer.address);
    
    console.log("Total tasks in contract:", totalTasks.toString());
    console.log("Your task count:", userTaskCount.toString());
    
    // Create your first task
    console.log("\n📝 Creating your first task...");
    const task1Title = "Learn CELO blockchain development";
    const task1Description = "Complete the CELO smart contract tutorial and deploy multiple contracts";
    const task1Priority = Priority.HIGH;
    const task1DueDate = Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60); // 1 week from now
    
    console.log("Task 1:", task1Title);
    console.log("Priority: HIGH");
    console.log("Due date: 1 week from now");
    
    const tx1 = await todoList.createTask(task1Title, task1Description, task1Priority, task1DueDate);
    console.log("✅ Transaction 1 sent! Hash:", tx1.hash);
    
    const receipt1 = await tx1.wait();
    console.log("🎉 Task 1 created in block:", receipt1.blockNumber);
    console.log("Gas used:", receipt1.gasUsed.toString());
    
    // Create your second task
    console.log("\n📝 Creating your second task...");
    const task2Title = "Build a TodoList dApp frontend";
    const task2Description = "Create a React frontend to interact with the TodoList smart contract";
    const task2Priority = Priority.MEDIUM;
    const task2DueDate = 0; // No due date
    
    console.log("Task 2:", task2Title);
    console.log("Priority: MEDIUM");
    console.log("Due date: No deadline");
    
    const tx2 = await todoList.createTask(task2Title, task2Description, task2Priority, task2DueDate);
    console.log("✅ Transaction 2 sent! Hash:", tx2.hash);
    
    const receipt2 = await tx2.wait();
    console.log("🎉 Task 2 created in block:", receipt2.blockNumber);
    
    // Create your third task
    console.log("\n📝 Creating your third task...");
    const task3Title = "Deploy more CELO contracts";
    const task3Description = "Explore and deploy additional smart contract types on CELO network";
    const task3Priority = Priority.LOW;
    const task3DueDate = Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60); // 1 month from now
    
    console.log("Task 3:", task3Title);
    console.log("Priority: LOW");
    console.log("Due date: 1 month from now");
    
    const tx3 = await todoList.createTask(task3Title, task3Description, task3Priority, task3DueDate);
    console.log("✅ Transaction 3 sent! Hash:", tx3.hash);
    
    const receipt3 = await tx3.wait();
    console.log("🎉 Task 3 created in block:", receipt3.blockNumber);
    
    // Check updated state
    console.log("\n📊 Updated Contract State:");
    const newTotalTasks = await todoList.totalTasks();
    const newUserTaskCount = await todoList.userTaskCount(signer.address);
    
    console.log("Total tasks in contract:", newTotalTasks.toString());
    console.log("Your task count:", newUserTaskCount.toString());
    
    // Get your task IDs
    const yourTasks = await todoList.getUserTasks(signer.address);
    console.log("Your task IDs:", yourTasks.map(id => id.toString()).join(", "));
    
    // Display your tasks
    console.log("\n📋 Your Tasks:");
    for (let i = 0; i < yourTasks.length; i++) {
      const taskId = yourTasks[i];
      const [id, title, description, priority, status, createdAt, updatedAt, dueDate, owner] = 
        await todoList.getTask(taskId);
      
      const priorityStr = await todoList.priorityToString(priority);
      const statusStr = await todoList.statusToString(status);
      const dueDateStr = dueDate > 0 ? new Date(Number(dueDate) * 1000).toLocaleDateString() : "No deadline";
      
      console.log(`\n${i + 1}. Task ID: ${id}`);
      console.log(`   Title: ${title}`);
      console.log(`   Description: ${description}`);
      console.log(`   Priority: ${priorityStr}`);
      console.log(`   Status: ${statusStr}`);
      console.log(`   Due Date: ${dueDateStr}`);
    }
    
    // Get user statistics
    console.log("\n📈 Your Statistics:");
    const [total, completed, pending, inProgress, cancelled, overdue] = 
      await todoList.getUserStats(signer.address);
    
    console.log("Total tasks:", total.toString());
    console.log("Completed:", completed.toString());
    console.log("Pending:", pending.toString());
    console.log("In Progress:", inProgress.toString());
    console.log("Cancelled:", cancelled.toString());
    console.log("Overdue:", overdue.toString());
    
    const completionRate = await todoList.getCompletionRate(signer.address);
    console.log("Completion Rate:", completionRate.toString() + "%");
    
    // Start working on the first task
    console.log("\n🚀 Starting work on your first task...");
    const startTx = await todoList.startTask(yourTasks[0]);
    console.log("✅ Task started! Hash:", startTx.hash);
    
    const startReceipt = await startTx.wait();
    console.log("🎉 Task status updated in block:", startReceipt.blockNumber);
    
    // Check the updated task
    const [, , , , newStatus] = await todoList.getTask(yourTasks[0]);
    const newStatusStr = await todoList.statusToString(newStatus);
    console.log("Task 1 new status:", newStatusStr);
    
    console.log("\n🔍 View your transactions on CeloScan:");
    console.log(`Task 1: https://celoscan.io/tx/${tx1.hash}`);
    console.log(`Task 2: https://celoscan.io/tx/${tx2.hash}`);
    console.log(`Task 3: https://celoscan.io/tx/${tx3.hash}`);
    console.log(`Start Task: https://celoscan.io/tx/${startTx.hash}`);
    
    console.log("\n🔍 View contract on CeloScan:");
    console.log(`https://celoscan.io/address/${todoListAddress}`);
    
  } catch (error) {
    console.error("❌ Transaction failed:", error.message);
    
    if (error.message.includes("insufficient funds")) {
      console.log("💡 You need more CELO for gas fees");
    } else if (error.message.includes("gas")) {
      console.log("💡 Try increasing gas price in hardhat.config.js");
    }
  }
  
  console.log("\n" + "=" * 60);
  console.log("🎉 TodoList contract interaction complete!");
  console.log("You now have a personal task management system on CELO blockchain!");
}

main().catch(console.error);
