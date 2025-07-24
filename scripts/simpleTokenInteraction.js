const { ethers } = require("hardhat");

async function main() {
  // Your deployed SimpleToken contract address
  const TOKEN_ADDRESS = "0xE4B29978983De62f319d693f7bB3B215D4a93A1E";
  
  console.log("🚀 Connecting to SimpleToken on CELO mainnet...");
  console.log("📍 Contract Address:", TOKEN_ADDRESS);
  
  // Get the contract
  const SimpleToken = await ethers.getContractFactory("SimpleToken");
  const token = SimpleToken.attach(TOKEN_ADDRESS);
  
  // Get the owner (your account)
  const [owner] = await ethers.getSigners();
  console.log("👤 Your Address:", owner.address);
  
  // Check basic token info
  console.log("\n📊 Token Information:");
  const name = await token.name();
  const symbol = await token.symbol();
  const totalSupply = await token.totalSupply();
  const ownerBalance = await token.balanceOf(owner.address);
  
  console.log(`Name: ${name}`);
  console.log(`Symbol: ${symbol}`);
  console.log(`Total Supply: ${ethers.formatEther(totalSupply)} ${symbol}`);
  console.log(`Your Balance: ${ethers.formatEther(ownerBalance)} ${symbol}`);
  
  // Create a test recipient address (you can replace with any address)
  const testRecipient = "0x742d35Cc6634C0532925a3b8D4C0C1e2b89f4c5c"; // Random test address
  
  console.log("\n📤 Making a transfer transaction...");
  console.log(`Transferring 10 ${symbol} to ${testRecipient}`);
  
  try {
    const transferAmount = ethers.parseEther("10");
    const tx = await token.transfer(testRecipient, transferAmount);
    
    console.log(`✅ Transaction sent! Hash: ${tx.hash}`);
    console.log("⏳ Waiting for confirmation...");
    
    const receipt = await tx.wait();
    console.log(`🎉 Transaction confirmed in block ${receipt.blockNumber}`);
    console.log(`💰 Gas used: ${receipt.gasUsed.toString()}`);
    
    // Check updated balances
    const newOwnerBalance = await token.balanceOf(owner.address);
    const recipientBalance = await token.balanceOf(testRecipient);
    
    console.log("\n💰 Updated Balances:");
    console.log(`Your Balance: ${ethers.formatEther(newOwnerBalance)} ${symbol}`);
    console.log(`Recipient Balance: ${ethers.formatEther(recipientBalance)} ${symbol}`);
    
    console.log(`\n🔍 View transaction on CeloScan: https://celoscan.io/tx/${tx.hash}`);
    
  } catch (error) {
    console.error("❌ Transaction failed:", error.message);
  }
}

main()
  .then(() => {
    console.log("\n✨ Interaction complete!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Script error:", error);
    process.exit(1);
  });
