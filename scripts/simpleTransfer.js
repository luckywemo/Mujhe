async function main() {
  const { ethers } = require("hardhat");
  
  console.log("🚀 Making a simple STK token transfer...");
  
  // Your contract address
  const tokenAddress = "0xE4B29978983De62f319d693f7bB3B215D4a93A1E";
  
  // Get contract and signer
  const SimpleToken = await ethers.getContractFactory("SimpleToken");
  const token = SimpleToken.attach(tokenAddress);
  const [signer] = await ethers.getSigners();
  
  console.log("Your address:", signer.address);
  
  // Check CELO balance first
  const celoBalance = await ethers.provider.getBalance(signer.address);
  console.log("CELO balance:", ethers.formatEther(celoBalance), "CELO");
  
  if (celoBalance < ethers.parseEther("0.001")) {
    console.log("❌ Insufficient CELO for gas fees");
    return;
  }
  
  // Check STK balance
  const stkBalance = await token.balanceOf(signer.address);
  console.log("STK balance:", ethers.formatEther(stkBalance), "STK");
  
  // Use a valid CELO address (CELO Foundation address)
  const recipient = "0x6cc083aed9e3ebe302a6336dbc7c921c9f03349e";
  const amount = ethers.parseEther("1"); // Just 1 STK token
  
  console.log(`\nTransferring 1 STK to: ${recipient}`);
  
  try {
    // Estimate gas first
    const gasEstimate = await token.transfer.estimateGas(recipient, amount);
    console.log("Estimated gas:", gasEstimate.toString());
    
    // Make the transfer
    const tx = await token.transfer(recipient, amount);
    console.log("✅ Transaction sent!");
    console.log("Hash:", tx.hash);
    console.log("Waiting for confirmation...");
    
    const receipt = await tx.wait();
    console.log("🎉 Transaction confirmed!");
    console.log("Block:", receipt.blockNumber);
    console.log("Gas used:", receipt.gasUsed.toString());
    
    // Check new balance
    const newBalance = await token.balanceOf(signer.address);
    console.log("New STK balance:", ethers.formatEther(newBalance), "STK");
    
    console.log(`\n🔍 View on CeloScan: https://celoscan.io/tx/${tx.hash}`);
    
  } catch (error) {
    console.error("❌ Transaction failed:", error.message);
    
    // Check if it's a gas issue
    if (error.message.includes("insufficient funds")) {
      console.log("💡 You need more CELO for gas fees");
      console.log("💡 Get CELO from: https://faucet.celo.org/alfajores (testnet) or buy on exchanges");
    }
  }
}

main().catch(console.error);
