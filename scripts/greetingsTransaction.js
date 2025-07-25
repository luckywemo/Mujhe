async function main() {
  const { ethers } = require("hardhat");
  
  console.log("🎯 Making a transaction on the Greetings contract...");
  console.log("=" * 60);
  
  // Your deployed Greetings contract address
  const greetingsAddress = "0x934Bf74bFD9dAafE88152a995B7c18b4881Fa488";
  
  // Get contract and signer
  const Greetings = await ethers.getContractFactory("Greetings");
  const greetings = Greetings.attach(greetingsAddress);
  const [signer] = await ethers.getSigners();
  
  console.log("📍 Contract Address:", greetingsAddress);
  console.log("👤 Your Address:", signer.address);
  
  try {
    // Check current contract state
    console.log("\n📊 Current Contract State:");
    const defaultGreeting = await greetings.defaultGreeting();
    const totalGreetings = await greetings.totalGreetings();
    const owner = await greetings.owner();
    
    console.log("Default Greeting:", defaultGreeting);
    console.log("Total Greetings:", totalGreetings.toString());
    console.log("Contract Owner:", owner);
    
    // Check if you already have a greeting
    const hasGreeting = await greetings.hasSetGreeting(signer.address);
    console.log("You have a greeting:", hasGreeting);
    
    if (hasGreeting) {
      const yourGreeting = await greetings.getGreeting(signer.address);
      console.log("Your current greeting:", yourGreeting);
    }
    
    // Set a new greeting
    const newGreeting = "Hello from CELO blockchain! This is my first greeting! 🚀";
    console.log("\n📝 Setting your greeting...");
    console.log("New greeting:", newGreeting);
    
    // Estimate gas first
    const gasEstimate = await greetings.setGreeting.estimateGas(newGreeting);
    console.log("Estimated gas:", gasEstimate.toString());
    
    // Make the transaction
    const tx = await greetings.setGreeting(newGreeting);
    console.log("✅ Transaction sent!");
    console.log("Transaction Hash:", tx.hash);
    console.log("⏳ Waiting for confirmation...");
    
    const receipt = await tx.wait();
    console.log("🎉 Transaction confirmed!");
    console.log("Block Number:", receipt.blockNumber);
    console.log("Gas Used:", receipt.gasUsed.toString());
    
    // Check updated state
    console.log("\n📊 Updated Contract State:");
    const newTotalGreetings = await greetings.totalGreetings();
    const yourNewGreeting = await greetings.getGreeting(signer.address);
    const [hasSet, updateCount, currentGreeting] = await greetings.getGreetingStats(signer.address);
    
    console.log("Total Greetings:", newTotalGreetings.toString());
    console.log("Your greeting:", yourNewGreeting);
    console.log("Your update count:", updateCount.toString());
    
    // Get latest greetings from the contract
    if (newTotalGreetings > 0) {
      console.log("\n📋 Latest Greetings:");
      const [addresses, greetingTexts] = await greetings.getLatestGreetings(3);
      for (let i = 0; i < addresses.length; i++) {
        console.log(`${i + 1}. ${addresses[i]}: "${greetingTexts[i]}"`);
      }
    }
    
    // Get contract statistics
    console.log("\n📈 Contract Statistics:");
    const [totalUsers, totalUpdates, currentDefault, contractOwner] = await greetings.getContractStats();
    console.log("Total Users:", totalUsers.toString());
    console.log("Total Updates:", totalUpdates.toString());
    
    console.log("\n🔍 View transaction on CeloScan:");
    console.log(`https://celoscan.io/tx/${tx.hash}`);
    console.log("\n🔍 View contract on CeloScan:");
    console.log(`https://celoscan.io/address/${greetingsAddress}`);
    
  } catch (error) {
    console.error("❌ Transaction failed:", error.message);
    
    // Check if it's a gas issue
    if (error.message.includes("insufficient funds")) {
      console.log("💡 You need more CELO for gas fees");
    } else if (error.message.includes("gas")) {
      console.log("💡 Try increasing gas price in hardhat.config.js");
    }
  }
  
  console.log("\n" + "=" * 60);
  console.log("🎉 Greetings contract interaction complete!");
}

main().catch(console.error);
