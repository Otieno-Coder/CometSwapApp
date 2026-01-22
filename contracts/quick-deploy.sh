#!/bin/bash
# Quick Deployment Script for CometSwap
# This script will deploy CollateralSwap to mainnet

set -e

RPC_URL="https://eth-mainnet.g.alchemy.com/v2/l8MuEZH4Xyi2Mq5gR42_C"

echo "🚀 CometSwap Deployment"
echo "======================"
echo ""

# Check for private key
if [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo "⚠️  DEPLOYER_PRIVATE_KEY not found in environment"
    echo ""
    read -sp "Enter your deployer private key (without 0x): " PRIVATE_KEY
    echo ""
    export DEPLOYER_PRIVATE_KEY="$PRIVATE_KEY"
fi

# Check for Etherscan key (optional)
VERIFY_FLAG=""
if [ -n "$ETHERSCAN_API_KEY" ]; then
    VERIFY_FLAG="--verify --etherscan-api-key $ETHERSCAN_API_KEY"
    echo "✅ Verification enabled"
else
    echo "⚠️  ETHERSCAN_API_KEY not set - skipping verification"
fi

echo ""
echo "📡 RPC URL: $RPC_URL"
echo "🔑 Deployer: $(cast wallet address --private-key $DEPLOYER_PRIVATE_KEY)"
echo ""
read -p "Continue with deployment? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 1
fi

echo ""
echo "🔨 Deploying CollateralSwap..."
echo ""

# Deploy
forge script script/DeployCollateralSwap.s.sol \
    --rpc-url "$RPC_URL" \
    --broadcast \
    $VERIFY_FLAG \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    -vvvv

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "1. Copy the deployed contract address from above"
echo "2. Update frontend/src/config/contracts.ts:"
echo "   COLLATERAL_SWAP: '0xYOUR_ADDRESS' as Address,"
echo "3. Rebuild frontend: cd ../frontend && npm run build"
