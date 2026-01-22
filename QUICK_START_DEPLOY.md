# 🚀 Quick Deployment Guide

## Deploy in 3 Steps

### Step 1: Set Your Private Key

```bash
export DEPLOYER_PRIVATE_KEY=your_private_key_without_0x
```

**⚠️ Security:** Never commit this to git! Use environment variables.

### Step 2: Deploy Contract

```bash
cd contracts
./quick-deploy.sh
```

Or manually:
```bash
cd contracts
forge script script/DeployCollateralSwap.s.sol \
  --rpc-url https://eth-mainnet.g.alchemy.com/v2/l8MuEZH4Xyi2Mq5gR42_C \
  --broadcast \
  --private-key $DEPLOYER_PRIVATE_KEY \
  -vvvv
```

### Step 3: Update Frontend

After deployment, copy the contract address from the output, then:

```bash
# From project root
./update-frontend-address.sh 0xYourDeployedAddress

# Rebuild frontend
cd frontend
npm run build
```

## That's It! 🎉

Your CometSwap dApp is now deployed and ready to use!

## Optional: Verify on Etherscan

If you want to verify the contract on Etherscan:

```bash
export ETHERSCAN_API_KEY=your_etherscan_key
./quick-deploy.sh
```

The script will automatically verify if the key is set.

## Need Help?

See `DEPLOYMENT.md` for detailed instructions.
