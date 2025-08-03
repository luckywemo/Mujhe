const hre = require("hardhat");

async function main() {
  // The address of the deployed PredictionMarket contract.
  const contractAddress = "0x3Ed9624930B82360e77d44149D6953f7972617E6";

  // The constructor arguments are derived from the Ignition module.
  // 1. The deployer's address
  // 2. The initial fee in basis points (100)
  const [deployer] = await hre.ethers.getSigners();
  const constructorArguments = [
    deployer.address, // The owner
    100,              // The initial fee (1%)
  ];

  console.log(`Verifying contract at ${contractAddress} on Celo mainnet...`);
  console.log(`Constructor arguments: ${constructorArguments.join(', ')}`);

  try {
    await hre.run("verify:verify", {
      address: contractAddress,
      constructorArguments: constructorArguments,
    });
    console.log("Contract verified successfully on CeloScan (Etherscan)!");
  } catch (error) {
    console.error("Verification failed:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
