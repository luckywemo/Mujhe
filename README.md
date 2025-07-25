# CELO Smart Contracts Project

This project demonstrates how to deploy multiple smart contracts on the CELO blockchain using Hardhat. The project includes three fully deployed and verified contracts:

- **SimpleToken**: An ERC-20 token with 1 million initial supply
- **SimpleStorage**: A data storage and retrieval contract
- **Greetings**: A social greetings platform contract
- **CELO Network Configuration**: Ready for both Alfajores testnet and mainnet
- **Deployment Scripts**: Using Hardhat Ignition and custom scripts

## Setup

1. **Install Dependencies**:
   ```bash
   npm install
   ```

2. **Environment Configuration**:
   - Copy `.env.example` to `.env`
   - Add your private key (without 0x prefix)
   - Optionally add CeloScan API key for verification

   ```bash
   cp .env.example .env
   ```

3. **Get Test Tokens** (for Alfajores testnet):
   - Visit [CELO Faucet](https://faucet.celo.org/alfajores)
   - Get test CELO tokens for deployment

## Deployment

### Deploy to Alfajores Testnet
```bash
npx hardhat ignition deploy ./ignition/modules/SimpleToken.js --network alfajores
```

### Deploy to CELO Mainnet
```bash
npx hardhat ignition deploy ./ignition/modules/SimpleToken.js --network celo
npx hardhat ignition deploy ./ignition/modules/SimpleStorage.js --network celo
npx hardhat run scripts/deployGreetings.js --network celo
```

## 🚀 Deployed Contracts (CELO Mainnet)

### 1. SimpleToken (ERC-20)
- **Address**: `0xE4B29978983De62f319d693f7bB3B215D4a93A1E`
- **Name**: SimpleToken
- **Symbol**: STK
- **Decimals**: 18
- **Initial Supply**: 1,000,000 STK
- **Features**: Mintable (owner only), Burnable
- **CeloScan**: https://celoscan.io/address/0xE4B29978983De62f319d693f7bB3B215D4a93A1E

### 2. SimpleStorage
- **Address**: `0xDCB0F5C4304491C2f8B43451731f8fF1580f3678`
- **Features**: Store/retrieve numbers and messages, address-specific storage, math functions
- **CeloScan**: https://celoscan.io/address/0xDCB0F5C4304491C2f8B43451731f8fF1580f3678

### 3. Greetings (Social Platform)
- **Address**: `0x934Bf74bFD9dAafE88152a995B7c18b4881Fa488`
- **Features**: Personal greetings (max 280 chars), social interactions, greeting history, random greetings
- **CeloScan**: https://celoscan.io/address/0x934Bf74bFD9dAafE88152a995B7c18b4881Fa488
- **Sourcify**: https://repo.sourcify.dev/contracts/full_match/42220/0x934Bf74bFD9dAafE88152a995B7c18b4881Fa488/

## Useful Commands

```bash
# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Check contract size
npx hardhat size-contracts

# Verify contract (after deployment)
npx hardhat verify --network alfajores <CONTRACT_ADDRESS>

# Interact with contracts
npx hardhat console --network celo

# Run transaction scripts
npx hardhat run scripts/simpleTransfer.js --network celo
```

## 🎯 Contract Interactions

### SimpleToken (STK)
```javascript
// In Hardhat console
const SimpleToken = await ethers.getContractFactory("SimpleToken");
const token = SimpleToken.attach("0xE4B29978983De62f319d693f7bB3B215D4a93A1E");

// Check balance
const balance = await token.balanceOf("YOUR_ADDRESS");
console.log("STK Balance:", ethers.formatEther(balance));

// Transfer tokens
await token.transfer("RECIPIENT_ADDRESS", ethers.parseEther("10"));
```

### Greetings Contract
```javascript
// In Hardhat console
const Greetings = await ethers.getContractFactory("Greetings");
const greetings = Greetings.attach("0x934Bf74bFD9dAafE88152a995B7c18b4881Fa488");

// Set your greeting
await greetings.setGreeting("Hello from CELO!");

// Get latest greetings
const [addresses, greetingTexts] = await greetings.getLatestGreetings(5);
console.log("Latest greetings:", greetingTexts);

// Get random greeting
const [greeter, greeting] = await greetings.getRandomGreeting();
console.log(`Random greeting from ${greeter}: ${greeting}`);
```

## 📊 Project Status

- ✅ **All contracts deployed** to CELO mainnet
- ✅ **All contracts verified** on CeloScan and Sourcify
- ✅ **Comprehensive test suites** for all contracts
- ✅ **Transaction scripts** ready for use
- ✅ **Development environment** fully configured

## Networks

- **Alfajores Testnet**: Chain ID 44787
- **CELO Mainnet**: Chain ID 42220

## Security Notes

- Never commit your `.env` file
- Use a dedicated wallet for deployments
- Test thoroughly on Alfajores before mainnet deployment
- All contracts are verified and transparent on the blockchain
