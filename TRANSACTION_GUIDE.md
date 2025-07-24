# SimpleToken Transaction Guide

## Your Deployed Contract
- **Address**: `0xE4B29978983De62f319d693f7bB3B215D4a93A1E`
- **Network**: CELO Mainnet
- **Explorer**: https://celoscan.io/address/0xE4B29978983De62f319d693f7bB3B215D4a93A1E

## Method 1: Using Hardhat Console

1. Open Hardhat console:
```bash
npx hardhat console --network celo
```

2. Connect to your contract:
```javascript
const SimpleToken = await ethers.getContractFactory("SimpleToken");
const token = SimpleToken.attach("0xE4B29978983De62f319d693f7bB3B215D4a93A1E");
```

3. Check your balance:
```javascript
const [owner] = await ethers.getSigners();
const balance = await token.balanceOf(owner.address);
console.log("Your balance:", ethers.formatEther(balance), "STK");
```

4. Make a transfer:
```javascript
const recipient = "0x742d35Cc6634C0532925a3b8D4C0C1e2b89f4c5c"; // Replace with any address
const amount = ethers.parseEther("10"); // 10 tokens
const tx = await token.transfer(recipient, amount);
console.log("Transaction hash:", tx.hash);
await tx.wait();
console.log("Transaction confirmed!");
```

5. Mint new tokens (owner only):
```javascript
const mintAmount = ethers.parseEther("100");
const mintTx = await token.mint(owner.address, mintAmount);
await mintTx.wait();
console.log("Minted 100 tokens!");
```

6. Burn tokens:
```javascript
const burnAmount = ethers.parseEther("50");
const burnTx = await token.burn(burnAmount);
await burnTx.wait();
console.log("Burned 50 tokens!");
```

## Method 2: Using CeloScan Web Interface

1. Visit: https://celoscan.io/address/0xE4B29978983De62f319d693f7bB3B215D4a93A1E
2. Click on "Contract" tab
3. Click on "Write Contract" 
4. Connect your wallet (MetaMask, Valora, etc.)
5. Use the functions:
   - `transfer`: Send tokens to another address
   - `mint`: Create new tokens (owner only)
   - `burn`: Destroy your tokens
   - `approve`: Allow another address to spend your tokens

## Method 3: Using Scripts

Run the transaction script:
```bash
npx hardhat run scripts/tokenTransaction.js --network celo
```

## Transaction Examples

### Transfer 10 STK tokens:
```javascript
await token.transfer("RECIPIENT_ADDRESS", ethers.parseEther("10"));
```

### Mint 500 new tokens:
```javascript
await token.mint("RECIPIENT_ADDRESS", ethers.parseEther("500"));
```

### Burn 25 tokens:
```javascript
await token.burn(ethers.parseEther("25"));
```

### Check token info:
```javascript
console.log("Name:", await token.name());
console.log("Symbol:", await token.symbol());
console.log("Total Supply:", ethers.formatEther(await token.totalSupply()));
```

## Important Notes

- All transactions require CELO for gas fees
- You are the owner, so you can mint new tokens
- Anyone can burn their own tokens
- Transfers require sufficient balance
- All transactions are permanent and public on the blockchain

## View Your Transactions

After making transactions, view them on CeloScan:
- Contract: https://celoscan.io/address/0xE4B29978983De62f319d693f7bB3B215D4a93A1E
- Your transactions will appear in the "Transactions" tab
