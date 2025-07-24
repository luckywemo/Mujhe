# CELO SimpleToken Project

This project demonstrates how to deploy a simple ERC-20 token on the CELO blockchain using Hardhat. The project includes:

- **SimpleToken**: An ERC-20 token with 1 million initial supply
- **CELO Network Configuration**: Ready for both Alfajores testnet and mainnet
- **Deployment Scripts**: Using Hardhat Ignition

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
```

## Contract Details

- **Name**: SimpleToken
- **Symbol**: STK
- **Decimals**: 18
- **Initial Supply**: 1,000,000 STK
- **Features**: Mintable (owner only), Burnable

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
```

## Networks

- **Alfajores Testnet**: Chain ID 44787
- **CELO Mainnet**: Chain ID 42220

## Security Notes

- Never commit your `.env` file
- Use a dedicated wallet for deployments
- Test thoroughly on Alfajores before mainnet deployment
