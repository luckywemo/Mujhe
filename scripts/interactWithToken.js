const { ethers } = require("hardhat");

async function main() {
  // Contract address of your deployed SimpleToken
  const TOKEN_ADDRESS = "0xE4B29978983De62f319d693f7bB3B215D4a93A1E";
  
  // Get the contract factory and attach to deployed contract
  const SimpleToken = await ethers.getContractFactory("SimpleToken");
  const token = SimpleToken.attach(TOKEN_ADDRESS);
  
  // Get signers (accounts)
  const [owner, addr1] = await ethers.getSigners();
  
  console.log("🚀 Interacting with SimpleToken on CELO mainnet");
  console.log("📍 Contract Address:", TOKEN_ADDRESS);
  console.log("👤 Owner Address:", owner.address);
  console.log("👤 Recipient Address:", addr1.address);
  console.log("=" * 50);
  
  try {
    // 1. Check basic token information
    console.log("\n📊 Token Information:");
    const name = await token.name();
    const symbol = await token.symbol();
    const decimals = await token.decimals();
    const totalSupply = await token.totalSupply();
    
    console.log(`Name: ${name}`);
    console.log(`Symbol: ${symbol}`);
    console.log(`Decimals: ${decimals}`);
    console.log(`Total Supply: ${ethers.formatEther(totalSupply)} ${symbol}`);
    
    // 2. Check owner's balance
    console.log("\n💰 Balance Information:");
    const ownerBalance = await token.balanceOf(owner.address);
    console.log(`Owner Balance: ${ethers.formatEther(ownerBalance)} ${symbol}`);
    
    // 3. Transfer tokens to another address
    console.log("\n📤 Making a Transfer Transaction:");
    const transferAmount = ethers.parseEther("100"); // Transfer 100 tokens
    console.log(`Transferring ${ethers.formatEther(transferAmount)} ${symbol} to ${addr1.address}...`);
    
    const transferTx = await token.transfer(addr1.address, transferAmount);
    console.log(`Transaction Hash: ${transferTx.hash}`);
    console.log("⏳ Waiting for confirmation...");
    
    const receipt = await transferTx.wait();
    console.log(`✅ Transfer confirmed in block ${receipt.blockNumber}`);
    console.log(`Gas Used: ${receipt.gasUsed.toString()}`);
    
    // 4. Check balances after transfer
    console.log("\n💰 Updated Balances:");
    const newOwnerBalance = await token.balanceOf(owner.address);
    const recipientBalance = await token.balanceOf(addr1.address);
    
    console.log(`Owner Balance: ${ethers.formatEther(newOwnerBalance)} ${symbol}`);
    console.log(`Recipient Balance: ${ethers.formatEther(recipientBalance)} ${symbol}`);
    
    // 5. Mint new tokens (owner only)
    console.log("\n🏭 Minting New Tokens:");
    const mintAmount = ethers.parseEther("500"); // Mint 500 tokens
    console.log(`Minting ${ethers.formatEther(mintAmount)} ${symbol} to owner...`);
    
    const mintTx = await token.mint(owner.address, mintAmount);
    console.log(`Mint Transaction Hash: ${mintTx.hash}`);
    console.log("⏳ Waiting for confirmation...");
    
    const mintReceipt = await mintTx.wait();
    console.log(`✅ Mint confirmed in block ${mintReceipt.blockNumber}`);
    
    // 6. Check updated total supply and owner balance
    console.log("\n📊 After Minting:");
    const newTotalSupply = await token.totalSupply();
    const finalOwnerBalance = await token.balanceOf(owner.address);
    
    console.log(`New Total Supply: ${ethers.formatEther(newTotalSupply)} ${symbol}`);
    console.log(`Owner Balance: ${ethers.formatEther(finalOwnerBalance)} ${symbol}`);
    
    // 7. Burn some tokens
    console.log("\n🔥 Burning Tokens:");
    const burnAmount = ethers.parseEther("50"); // Burn 50 tokens
    console.log(`Burning ${ethers.formatEther(burnAmount)} ${symbol}...`);
    
    const burnTx = await token.burn(burnAmount);
    console.log(`Burn Transaction Hash: ${burnTx.hash}`);
    console.log("⏳ Waiting for confirmation...");
    
    const burnReceipt = await burnTx.wait();
    console.log(`✅ Burn confirmed in block ${burnReceipt.blockNumber}`);
    
    // 8. Final state
    console.log("\n🏁 Final State:");
    const finalTotalSupply = await token.totalSupply();
    const veryFinalOwnerBalance = await token.balanceOf(owner.address);
    
    console.log(`Final Total Supply: ${ethers.formatEther(finalTotalSupply)} ${symbol}`);
    console.log(`Final Owner Balance: ${ethers.formatEther(veryFinalOwnerBalance)} ${symbol}`);
    console.log(`Recipient Balance: ${ethers.formatEther(recipientBalance)} ${symbol}`);
    
    console.log("\n🎉 All transactions completed successfully!");
    console.log(`🔍 View all transactions on CeloScan: https://celoscan.io/address/${TOKEN_ADDRESS}`);
    
  } catch (error) {
    console.error("❌ Error during transaction:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
