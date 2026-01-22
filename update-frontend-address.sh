#!/bin/bash
# Update frontend config with deployed contract address
# Usage: ./update-frontend-address.sh 0xYourContractAddress

if [ -z "$1" ]; then
    echo "Usage: ./update-frontend-address.sh 0xYourContractAddress"
    exit 1
fi

CONTRACT_ADDRESS="$1"
CONFIG_FILE="frontend/src/config/contracts.ts"

# Validate address format
if [[ ! "$CONTRACT_ADDRESS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    echo "❌ Invalid address format: $CONTRACT_ADDRESS"
    exit 1
fi

# Update the config file
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/COLLATERAL_SWAP: '0x[^']*'/COLLATERAL_SWAP: '${CONTRACT_ADDRESS}'/" "$CONFIG_FILE"
else
    # Linux
    sed -i "s/COLLATERAL_SWAP: '0x[^']*'/COLLATERAL_SWAP: '${CONTRACT_ADDRESS}'/" "$CONFIG_FILE"
fi

echo "✅ Updated frontend config with address: $CONTRACT_ADDRESS"
echo ""
echo "📝 Next: Rebuild frontend"
echo "   cd frontend && npm run build"
