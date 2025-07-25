async function main() {
  const { ethers } = require("hardhat");
  
  console.log("🚀 Deploying Greetings contract to CELO mainnet...");
  
  // Get the contract factory
  const Greetings = await ethers.getContractFactory("Greetings");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  
  // Check balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "CELO");
  
  try {
    // Deploy the contract
    console.log("Deploying Greetings contract...");
    const greetings = await Greetings.deploy();
    
    console.log("⏳ Waiting for deployment confirmation...");
    await greetings.waitForDeployment();
    
    const contractAddress = await greetings.getAddress();
    console.log("✅ Greetings contract deployed successfully!");
    console.log("📍 Contract Address:", contractAddress);
    
    // Verify the deployment by calling a function
    const defaultGreeting = await greetings.defaultGreeting();
    const owner = await greetings.owner();
    
    console.log("\n📊 Contract Info:");
    console.log("Default Greeting:", defaultGreeting);
    console.log("Owner:", owner);
    console.log("Total Greetings:", (await greetings.totalGreetings()).toString());
    
    console.log("\n🔍 View on CeloScan:");
    console.log(`https://celoscan.io/address/${contractAddress}`);
    
    console.log("\n🎉 Deployment complete!");
    
    return contractAddress;
    
  } catch (error) {
    console.error("❌ Deployment failed:", error.message);
    throw error;
  }
}

main()
  .then((address) => {
    console.log(`\n✨ Greetings contract deployed at: ${address}`);
    process.exit(0);
  })
  .catch((error) => {
    console.error("💥 Deployment error:", error);
    process.exit(1);
  });
