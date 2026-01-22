# 🌠 CometSwap - Collateral Swap for Compound V3

> Atomically swap your Compound V3 collateral without exiting your position

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Built with Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://getfoundry.sh/)
[![Next.js](https://img.shields.io/badge/Next.js-15-black.svg)](https://nextjs.org/)

## Overview

CometSwap enables users to swap between different collateral types in Compound V3 (Comet) markets without:
- Closing their position
- Risking liquidation during the swap
- Multiple transactions

The entire swap happens atomically in a single transaction using Aave V3 flash loans and Uniswap V3 for optimal execution.

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CollateralSwap Flow                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. User initiates swap (WETH → WBTC)                              │
│     ↓                                                               │
│  2. Flash borrow WBTC from Aave                                     │
│     ↓                                                               │
│  3. Supply WBTC to Comet as new collateral                         │
│     ↓                                                               │
│  4. Withdraw WETH from Comet (user's old collateral)               │
│     ↓                                                               │
│  5. Swap WETH → WBTC on Uniswap V3                                 │
│     ↓                                                               │
│  6. Repay flash loan + 0.05% fee                                   │
│     ↓                                                               │
│  7. Return excess to user                                          │
│                                                                     │
│  ✅ All steps atomic - reverts if any step fails                   │
└─────────────────────────────────────────────────────────────────────┘
```

## Features

- ⚡ **Atomic Execution**: All-or-nothing swap in single transaction
- 💰 **No Protocol Fees**: Only pay flash loan (0.05%) and swap fees
- 🛡️ **Stay Collateralized**: Never risk liquidation during swap
- 🔄 **Multiple Assets**: Support for WETH, WBTC, COMP, UNI, LINK
- 📊 **Live Stats**: Real-time protocol data from Compound V3

## Project Structure

```
cometswap/
├── contracts/              # Foundry smart contracts
│   ├── src/
│   │   ├── CollateralSwap.sol       # Main swap contract
│   │   ├── FlashLoanReceiverBase.sol
│   │   └── interfaces/              # Protocol interfaces
│   ├── test/                        # Integration tests
│   └── script/                      # Deployment scripts
│
├── frontend/               # Next.js frontend
│   └── src/
│       ├── app/                     # Pages
│       ├── components/              # React components
│       ├── hooks/                   # Custom hooks
│       └── config/                  # Contract configs
│
└── docs/                   # Documentation
```

## Quick Start

### Prerequisites

- [Node.js](https://nodejs.org/) v18+
- [Foundry](https://getfoundry.sh/) 
- [Git](https://git-scm.com/)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/cometswap.git
cd cometswap

# Install contract dependencies
cd contracts
forge install

# Install frontend dependencies
cd ../frontend
npm install
```

### Environment Setup

```bash
# Contracts
cd contracts
cp env.example .env
# Edit .env with your RPC URLs and keys

# Frontend
cd ../frontend
cp .env.example .env.local
# Edit .env.local with your config
```

### Running Tests

```bash
# Run all contract tests (requires MAINNET_RPC_URL in .env)
cd contracts
forge test -vvv

# Run specific test file
forge test --match-path test/CollateralSwapIntegration.t.sol -vvv
```

### Running Frontend

```bash
cd frontend
npm run dev
# Open http://localhost:3000
```

## Deployment

### Deploy to Mainnet Fork (Testing)

```bash
# Terminal 1: Start Anvil fork
anvil --fork-url $MAINNET_RPC_URL

# Terminal 2: Deploy
cd contracts
forge script script/DeployCollateralSwap.s.sol:DeployCollateralSwapFork \
  --rpc-url http://localhost:8545 \
  --broadcast -vvvv
```

### Deploy to Mainnet (Production)

```bash
cd contracts
forge script script/DeployCollateralSwap.s.sol \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvvv
```

### Post-Deployment

1. Update `frontend/src/config/contracts.ts` with deployed address:
   ```typescript
   COLLATERAL_SWAP: '0xYOUR_DEPLOYED_ADDRESS' as Address,
   ```

2. Verify contract on Etherscan (if not auto-verified)

3. Test with small amounts first!

## Contract Addresses

### Mainnet

| Contract | Address |
|----------|---------|
| CollateralSwap | `TBD` |
| Comet USDC | `0xc3d688B66703497DAA19211EEdff47f25384cdc3` |
| Aave Pool | `0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2` |
| Uniswap Router | `0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45` |

## Security Considerations

- ⚠️ This code has NOT been audited
- User must `allow()` CollateralSwap on Comet before using
- Health factor validated before and after swap
- ReentrancyGuard protection on all external calls
- Owner-only admin functions

## User Flow

1. **Connect Wallet** on the frontend
2. **Approve CollateralSwap** to manage your Comet position (one-time)
3. **Select Tokens**: Choose source and target collateral
4. **Enter Amount**: Specify how much to swap
5. **Review Quote**: Check exchange rate, fees, and slippage
6. **Execute Swap**: Confirm transaction in wallet
7. **Done!** Your collateral is swapped atomically

## Tech Stack

**Contracts:**
- Solidity 0.8.24
- Foundry (Forge, Cast, Anvil)
- OpenZeppelin Contracts

**Frontend:**
- Next.js 15
- React 19
- wagmi + viem
- RainbowKit
- TailwindCSS

**Integrations:**
- Compound V3 (Comet)
- Aave V3 (Flash Loans)
- Uniswap V3 (DEX)

## Testing

The project includes comprehensive tests:

| Test Suite | Tests | Description |
|------------|-------|-------------|
| FlashLoanTest | 8 | Flash loan execution |
| CometIntegration | 8 | Compound V3 interactions |
| UniswapIntegration | 8 | DEX swap tests |
| CollateralSwapIntegration | 9 | Full flow tests |

Run with verbose output:
```bash
forge test -vvvv --match-contract CollateralSwapIntegration
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Compound Finance](https://compound.finance/) - V3 Protocol
- [Aave](https://aave.com/) - Flash Loans
- [Uniswap](https://uniswap.org/) - DEX
- [Foundry](https://getfoundry.sh/) - Development Framework
- Built for the **Compound Grants Program**

---

<p align="center">
  <strong>⚠️ Use at your own risk. This is experimental software.</strong>
</p>
