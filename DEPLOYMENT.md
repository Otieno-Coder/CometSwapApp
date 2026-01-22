# 🚀 CometSwap Deployment Guide

## Prerequisites

1. **Private Key**: Your deployer wallet private key (without `0x` prefix)
2. **Etherscan API Key**: For contract verification (optional but recommended)
3. **ETH Balance**: Enough ETH in deployer wallet for gas fees (~0.01-0.02 ETH)

## Step 1: Set Environment Variables

```bash
cd contracts

# Create .env file
cat > .env << EOF
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/l8MuEZH4Xyi2Mq5gR42_C
DEPLOYER_PRIVATE_KEY=your_private_key_without_0x_prefix
ETHERSCAN_API_KEY=your_etherscan_api_key
EOF
```

## Step 2: Deploy Contract

### Option A: Using the deployment script

```bash
cd contracts
./deploy.sh --verify
```

### Option B: Using Forge directly

```bash
cd contracts
forge script script/DeployCollateralSwap.s.sol \
  --rpc-url https://eth-mainnet.g.alchemy.com/v2/l8MuEZH4Xyi2Mq5gR42_C \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --private-key $DEPLOYER_PRIVATE_KEY \
  -vvvv
```

## Step 3: Copy Deployed Address

After deployment, you'll see output like:
```
CollateralSwap deployed at: 0x...
```

**Copy this address!**

## Step 4: Update Frontend Config

Edit `frontend/src/config/contracts.ts`:

```typescript
// CollateralSwap (to be deployed)
COLLATERAL_SWAP: '0xYOUR_DEPLOYED_ADDRESS_HERE' as Address,
```

Replace `0xYOUR_DEPLOYED_ADDRESS_HERE` with the actual deployed address.

## Step 5: Rebuild Frontend

```bash
cd frontend
npm run build
```

## Step 6: Verify on Etherscan

1. Go to https://etherscan.io/address/YOUR_CONTRACT_ADDRESS
2. If auto-verification worked, you'll see the source code
3. If not, manually verify using the contract's ABI and source code

## Post-Deployment Checklist

- [ ] Contract deployed successfully
- [ ] Contract address updated in frontend config
- [ ] Frontend rebuilt with new address
- [ ] Contract verified on Etherscan
- [ ] Test with small amount first!

## Gas Cost Estimate

- Deployment: ~2,500,000 gas (~$50-100 depending on gas price)
- Adding collaterals: ~50,000 gas per collateral (~$1-2 each)

## Troubleshooting

### "Insufficient funds"
- Make sure your deployer wallet has enough ETH

### "Verification failed"
- Check your Etherscan API key
- Try manual verification on Etherscan

### "RPC error"
- Check your RPC URL is correct
- Make sure you have API quota remaining

## Security Reminder

⚠️ **NEVER commit your private key to git!**
- Keep `.env` in `.gitignore`
- Use environment variables or secure key management
