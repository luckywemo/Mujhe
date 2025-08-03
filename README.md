# CELO Smart Contract Portfolio

This project is a comprehensive portfolio of **12 unique smart contracts** designed, tested, deployed, and verified on the CELO blockchain using Hardhat. It showcases a wide range of capabilities, from simple ERC-20 tokens to complex DeFi primitives like an NFT marketplace and a decentralized prediction market.

### Core Technologies
- **Solidity** for smart contract development
- **Hardhat** for the development environment, testing, and deployment
- **OpenZeppelin Contracts** for secure, reusable components
- **Hardhat Ignition** for robust, repeatable deployments
- **CeloScan & Sourcify** for public source code verification

## 🚀 Deployed Contracts (CELO Mainnet)

Below is a summary of all contracts deployed to the CELO mainnet. Each contract is verified on CeloScan, ensuring transparency and auditability.

### 1. SimpleToken (ERC-20)
- **Description**: A standard ERC-20 token.
- **Address**: `0xE4B29978983De62f319d693f7bB3B215D4a93A1E`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0xE4B29978983De62f319d693f7bB3B215D4a93A1E#code)

### 2. SimpleStorage
- **Description**: A basic contract for storing and retrieving on-chain data.
- **Address**: `0xDCB0F5C4304491C2f8B43451731f8fF1580f3678`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0xDCB0F5C4304491C2f8B43451731f8fF1580f3678#code)

### 3. Greetings
- **Description**: A simple social contract for posting public messages.
- **Address**: `0x934Bf74bFD9dAafE88152a995B7c18b4881Fa488`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0x934Bf74bFD9dAafE88152a995B7c18b4881Fa488#code)

### 4. Counter
- **Description**: An interactive contract that tracks a public number with history.
- **Address**: `0xf60e41F3155411b9E2422b6A5865c81d1b6FA40d`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0xf60e41F3155411b9E2422b6A5865c81d1b6FA40d#code)

### 5. TodoList
- **Description**: A personal on-chain task management dApp.
- **Address**: `0xD50fCE5736019dB84f7033Ab18Aa36064035625c`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0xD50fCE5736019dB84f7033Ab18Aa36064035625c#code)

### 6. VotingSystem
- **Description**: A decentralized governance system for creating and voting on proposals.
- **Address**: `0x75E3479A9C11BCa47ff08fc1f2c6e4fD695eDEB8`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0x75E3479A9C11BCa47ff08fc1f2c6e4fD695eDEB8#code)

### 7. NFTMarketplace
- **Description**: A full-featured marketplace for minting, buying, and selling NFTs with royalty support.
- **Address**: `0x4A6824768C7813D33d874d46998Fd2a499223b53`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0x4A6824768C7813D33d874d46998Fd2a499223b53#code)

### 8. Time-Locked Multi-Signature Wallet
- **Description**: An enterprise-grade multi-sig wallet with time-locks and daily spending limits.
- **Address**: `0x4c7384D3A3F6c9eB456e1eF778717936E5cd25a7`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0x4c7384D3A3F6c9eB456e1eF778717936E5cd25a7#code)

### 9. Message Board
- **Description**: An on-chain, decentralized message board where users can post public messages.
- **Address**: `0xA3Af6C73243c4b65fCeF11008063290fdb1B59A1`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0xA3Af6C73243c4b65fCeF11008063290fdb1B59A1#code)

### 10. Random Number Generator
- **Description**: A contract providing verifiable on-chain random numbers using block data.
- **Address**: `0xfB8B4D533D849B02ae70a4B9747bBa88f31E7C24`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0xfB8B4D533D849B02ae70a4B9747bBa88f31E7C24#code)

### 11. Tip Jar
- **Description**: A simple, on-chain contract for sending tips and messages to a creator.
- **Address**: `0x8c7FF72Cd2AfBa97Bf4F1a42D1e50e01E114a1AE`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0x8c7FF72Cd2AfBa97Bf4F1a42D1e50e01E114a1AE#code)

### 12. Decentralized Prediction Market
- **Description**: A DeFi platform for creating and trading on the outcomes of future events.
- **Address**: `0x3Ed9624930B82360e77d44149D6953f7972617E6`
- **CeloScan**: [View on CeloScan](https://celoscan.io/address/0x3Ed9624930B82360e77d44149D6953f7972617E6#code)

## Setup and Usage

1.  **Install Dependencies**:
    ```bash
    npm install
    ```

2.  **Environment Configuration**:
    - Copy `.env.example` to `.env` and add your private key and an optional CeloScan API key.

3.  **Compile, Test, and Deploy**:
    ```bash
    # Compile contracts
    npx hardhat compile

    # Run tests
    npx hardhat test

    # Deploy a module via Ignition
    npx hardhat ignition deploy ./ignition/modules/YourModule.js --network celo
    ```

## 🎯 Project Status

- ✅ **12 unique contracts deployed** to the CELO mainnet.
- ✅ **All contracts fully verified** on CeloScan for transparency.
- ✅ **Comprehensive test suites** implemented for all major contracts.
- ✅ **Robust deployment scripts** using Hardhat Ignition and custom scripts.
- ✅ **Development environment** fully configured for the CELO ecosystem.
