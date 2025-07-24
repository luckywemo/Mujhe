async function main() {
  const hre = require("hardhat");
  const { ethers } = hre;
  
  // Your SimpleToken contract address
  const tokenAddress = "0xE4B29978983De62f319d693f7bB3B215D4a93A1E";
  
  console.log("=".repeat(50));
  console.log("🚀 SimpleToken Transaction Demo on CELO");
  console.log("=".repeat(50));
  
  // Get contract instance
  const SimpleToken = await ethers.getContractFactory("SimpleToken");
  const token = SimpleToken.attach(tokenAddress);
  
  // Get signer (your account)
  const [signer] = await ethers.getSigners();
  
  console.log("📍 Contract Address:", tokenAddress);
  console.log("👤 Your Address:", signer.address);
  
  try {
    // Get token info
    const name = await token.name();
    const symbol = await token.symbol();
    const balance = await token.balanceOf(signer.address);
    
    console.log("\n📊 Token Info:");
    console.log("Name:", name);
    console.log("Symbol:", symbol);
    console.log("Your Balance:", ethers.formatEther(balance), symbol);
    
    // Make a transfer to a test address
    const recipient = "0x742d35Cc6634C0532925a3b8D4C0C1e2b89f4c5c";
    const amount = ethers.parseEther("5"); // Transfer 5 tokens
    
    console.log("\n📤 Making Transfer:");
    console.log("To:", recipient);
    console.log("Amount:", ethers.formatEther(amount), symbol);
    
    // Execute transfer
    const tx = await token.transfer(recipient, amount);
    console.log("Transaction Hash:", tx.hash);
    
    // Wait for confirmation
    console.log("⏳ Waiting for confirmation...");
    const receipt = await tx.wait();
    
    console.log("\n✅ Transaction Confirmed!");
    console.log("Block Number:", receipt.blockNumber);
    console.log("Gas Used:", receipt.gasUsed.toString());
    
    // Check new balance
    const newBalance = await token.balanceOf(signer.address);
    console.log("\n💰 New Balance:", ethers.formatEther(newBalance), symbol);
    
    console.log("\n🔍 View on CeloScan:");
    console.log(`https://celoscan.io/tx/${tx.hash}`);
    
  } catch (error) {
    console.error("\n❌ Error:", error.message);
  }
  
  console.log("\n" + "=".repeat(50));
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
