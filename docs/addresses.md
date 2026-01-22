# Comet Collateral Swap - Sepolia Testnet Addresses

> **Last Updated:** January 21, 2026
> **Network:** Ethereum Sepolia (Chain ID: 11155111)

## Status Legend
- ✅ Verified (official docs or on-chain confirmed)
- ⚠️ Unverified (community reported, needs testing)

---

## Compound V3 (Comet) - USDC Market ✅

**Source:** [GitHub - compound-finance/comet](https://github.com/compound-finance/comet/tree/main/deployments/sepolia/usdc)

| Contract | Address | Notes |
|----------|---------|-------|
| **Comet (cUSDCv3)** | `0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e` | Main proxy - use this for all interactions |
| Configurator | `0xc28aD44975C614EaBe0Ed090207314549e1c6624` | |
| CometRewards | `0x8bF5b658bdF0388E8b482ED51B14aef58f90abfD` | For claiming COMP rewards |
| Bulker | `0x157c001bb1F8b33743B14483Be111C961d8e11dE` | For batching operations |
| Fauceteer | `0x68793eA49297eB75DFB4610B68e076D2A5c7646C` | For getting test tokens |

### Base Asset (USDC Market)
| Token | Address | Decimals | Price Feed |
|-------|---------|----------|------------|
| USDC | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` | 6 | `0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E` |

### Collateral Assets (USDC Market)
| Token | Address | Decimals | Borrow CF | Liquidate CF | Supply Cap |
|-------|---------|----------|-----------|--------------|------------|
| WETH | *(see below)* | 18 | 82% | 85% | 1,000,000 |
| WBTC | *(see below)* | 8 | 70% | 75% | 35,000 |
| COMP | *(see below)* | 18 | 65% | 70% | 500,000 |

---

## Compound V3 (Comet) - WETH Market ✅

**Source:** [GitHub - compound-finance/comet](https://github.com/compound-finance/comet/tree/main/deployments/sepolia/weth)

| Contract | Address | Notes |
|----------|---------|-------|
| **Comet (cWETHv3)** | `0x2943ac1216979aD8dB76D9147F64E61adc126e96` | Main proxy |
| Configurator | `0xc28aD44975C614EaBe0Ed090207314549e1c6624` | Shared |
| CometRewards | `0x8bF5b658bdF0388E8b482ED51B14aef58f90abfD` | Shared |
| Bulker | `0xaD0C044425D81a2E223f4CE699156900fead2Aaa` | |
| Fauceteer | `0x68793eA49297eB75DFB4610B68e076D2A5c7646C` | Shared |

---

## Uniswap V3 ✅

**Source:** [Uniswap Docs](https://docs.uniswap.org/contracts/v3/reference/deployments/ethereum-deployments)

| Contract | Address | Status |
|----------|---------|--------|
| Factory | `0x0227628f3F023bb0B980b67D528571c95c6DaC1c` | ✅ |
| SwapRouter02 | `0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E` | ✅ |
| UniversalRouter | `0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD` | ✅ |
| Quoter V2 | `0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3` | ✅ |
| WETH9 | `0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14` | ✅ |
| Multicall2 | `0xD7F33bCdb21b359c8ee6F0251d30E94832baAd07` | ✅ |

---

## Aave V3 ✅

**Source:** Community verified + **Fork tested on 2026-01-21**

| Contract | Address | Status |
|----------|---------|--------|
| PoolAddressesProvider | `0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A` | ✅ |
| Pool | `0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951` | ✅ Fork tested |

### Flash Loan Info
- Flash loan fee: **0.05%** (5 basis points) ✅ Verified
- Method: `flashLoanSimple()` for single asset
- Method: `flashLoan()` for multiple assets
- **WETH flash loans are DISABLED** (error code 27)

### ⚠️ IMPORTANT: Aave Uses Different Testnet Tokens!

Aave V3 on Sepolia uses its **own testnet token addresses**, different from Comet/Circle tokens!

| Token | Aave Address | Pool Balance | Flash Loan Status |
|-------|--------------|--------------|-------------------|
| **USDC** | `0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8` | ~20,000 | ✅ **VERIFIED WORKING** |
| DAI | `0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357` | ~11,000 | Untested |
| USDT | `0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0` | ~2,000 | Untested |
| WBTC | `0x29f2D40B0605204364af54EC677bD022dA425d03` | ~0.01 | Untested |
| LINK | `0xf8Fb3713D459D7C1018BD0A49D19b4C44290EBE5` | 0 | No liquidity |

**For Comet Collateral Swap:** Since Aave and Comet use different tokens, we'll need to:
1. Use mainnet fork for integrated testing, OR
2. Bridge/swap between Aave tokens and Comet tokens

---

## Test Tokens (Sepolia)

| Token | Address | Decimals | Source |
|-------|---------|----------|--------|
| **USDC** | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` | 6 | Comet config (Circle test USDC) |
| **WETH** | `0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14` | 18 | Uniswap WETH9 |
| COMP | *Need to find* | 18 | Comet rewards token |
| WBTC | *Need to find* | 8 | Comet collateral |

---

## Chainlink Price Feeds (Sepolia)

| Pair | Address | Notes |
|------|---------|-------|
| USDC/USD | `0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E` | From Comet config |
| ETH/USD | `0x694AA1769357215DE4FAC081bf1f309aDC325306` | From Comet config |
| BTC/USD | `0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43` | From Comet config |
| COMP/USD | `0x619db7F74C0061E2917D1D57f834D9D24C5529dA` | From Comet config |

---

## Network Configuration

```json
{
  "chainId": 11155111,
  "name": "Sepolia",
  "rpc": [
    "https://rpc.sepolia.org",
    "https://sepolia.infura.io/v3/YOUR_KEY",
    "https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY"
  ],
  "explorer": "https://sepolia.etherscan.io",
  "faucets": [
    "https://sepoliafaucet.com",
    "https://www.alchemy.com/faucets/ethereum-sepolia",
    "Comet Fauceteer: 0x68793eA49297eB75DFB4610B68e076D2A5c7646C"
  ]
}
```

---

## Quick Reference for Development

### For Collateral Swap (USDC Market)

```solidity
// Comet USDC Market
address constant COMET_USDC = 0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e;

// Base Asset
address constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

// Collateral Assets  
address constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
// WBTC and COMP addresses need verification

// Aave Flash Loans
address constant AAVE_POOL_PROVIDER = 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A;

// Uniswap Swap
address constant SWAP_ROUTER = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;
```

---

## Resources

- [Compound V3 Docs](https://docs.compound.finance/)
- [Compound V3 GitHub](https://github.com/compound-finance/comet)
- [Aave V3 Docs](https://docs.aave.com/)
- [Uniswap V3 Docs](https://docs.uniswap.org/)
- [Sepolia Etherscan](https://sepolia.etherscan.io/)
- [Comet Fauceteer](https://sepolia.etherscan.io/address/0x68793eA49297eB75DFB4610B68e076D2A5c7646C) - Get test tokens!
