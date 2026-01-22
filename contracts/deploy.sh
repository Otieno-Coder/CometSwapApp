#!/bin/bash
# CometSwap Deployment Script
# Usage: ./deploy.sh [--verify]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== CometSwap Deployment ===${NC}"

# Check for required environment variables
if [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo -e "${RED}ERROR: DEPLOYER_PRIVATE_KEY not set${NC}"
    echo "Please set it in your .env file or export it:"
    echo "  export DEPLOYER_PRIVATE_KEY=your_private_key_here"
    exit 1
fi

if [ -z "$MAINNET_RPC_URL" ]; then
    echo -e "${RED}ERROR: MAINNET_RPC_URL not set${NC}"
    exit 1
fi

# Set RPC URL (use provided one or from env)
RPC_URL="${MAINNET_RPC_URL:-https://eth-mainnet.g.alchemy.com/v2/l8MuEZH4Xyi2Mq5gR42_C}"

echo -e "${YELLOW}RPC URL:${NC} $RPC_URL"
echo ""

# Build verification flags
VERIFY_FLAGS=""
if [ "$1" == "--verify" ]; then
    if [ -z "$ETHERSCAN_API_KEY" ]; then
        echo -e "${YELLOW}WARNING: ETHERSCAN_API_KEY not set, skipping verification${NC}"
    else
        VERIFY_FLAGS="--verify --etherscan-api-key $ETHERSCAN_API_KEY"
        echo -e "${GREEN}Verification enabled${NC}"
    fi
fi

# Deploy
echo -e "${GREEN}Deploying CollateralSwap...${NC}"
forge script script/DeployCollateralSwap.s.sol \
    --rpc-url "$RPC_URL" \
    --broadcast \
    $VERIFY_FLAGS \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    -vvvv

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy the deployed contract address from above"
echo "2. Update frontend/src/config/contracts.ts with the address"
echo "3. Rebuild the frontend: cd ../frontend && npm run build"
