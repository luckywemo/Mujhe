async function main() {
  const { ethers } = require("hardhat");
  
  console.log("🎯 Setting your first greeting on CELO!");
  
  // Contract address
  const greetingsAddress = "0x934Bf74bFD9dAafE88152a995B7c18b4881Fa488";
  
  // Get contract
  const Greetings = await ethers.getContractFactory("Greetings");
  const greetings = Greetings.attach(greetingsAddress);
  const [signer] = await ethers.getSigners();
  
  console.log("Contract:", greetingsAddress);
  console.log("Your address:", signer.address);
  
  // Check CELO balance
  const balance = await ethers.provider.getBalance(signer.address);
  console.log("CELO balance:", ethers.formatEther(balance));
  
  // Set greeting
  const greeting = "Hello CELO! My sixth greeting from DruxAMB!";
  console.log("Setting greeting:", greeting);
  
  try {
    const tx = await greetings.setGreeting(greeting);
    console.log("TX Hash:", tx.hash);
    
    const receipt = await tx.wait();
    console.log("✅ Success! Block:", receipt.blockNumber);
    console.log("Gas used:", receipt.gasUsed.toString());
    
    // Verify the greeting was set
    const myGreeting = await greetings.getMyGreeting();
    console.log("Your greeting:", myGreeting);
    
    console.log("🔍 View on CeloScan:");
    console.log(`https://celoscan.io/tx/${tx.hash}`);
    
  } catch (error) {
    console.error("Error:", error.message);
  }
}

main().catch(console.error);
