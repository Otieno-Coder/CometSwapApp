#!/bin/bash
# Quick setup script for test accounts

RPC="http://127.0.0.1:8545"
COMET="0xc3d688B66703497DAA19211EEdff47f25384cdc3"
WETH="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
COMP="0xc00e94Cb662C3520282E6f5717214004A7f26888"

# User 1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
USER1="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
USER1_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

# User 2: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC  
USER2="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
USER2_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"

echo "Setting up User 1 with 10 WETH..."
# Give WETH
cast rpc anvil_setBalance $USER1 10000000000000000000000 --rpc-url $RPC > /dev/null
cast rpc anvil_impersonateAccount $USER1 --rpc-url $RPC > /dev/null

# Approve and supply
cast send $WETH "approve(address,uint256)" $COMET 10000000000000000000 --from $USER1 --rpc-url $RPC --unlocked > /dev/null
cast send $COMET "supply(address,uint256)" $WETH 10000000000000000000 --from $USER1 --rpc-url $RPC --unlocked > /dev/null

echo "User 1 setup complete!"
echo "User 1 address: $USER1"
echo "WETH collateral: 10 ETH"

echo ""
echo "Setting up User 2 with 5 WETH + 100 COMP..."
cast rpc anvil_impersonateAccount $USER2 --rpc-url $RPC > /dev/null

# Approve and supply WETH
cast send $WETH "approve(address,uint256)" $COMET 5000000000000000000 --from $USER2 --rpc-url $RPC --unlocked > /dev/null
cast send $COMET "supply(address,uint256)" $WETH 5000000000000000000 --from $USER2 --rpc-url $RPC --unlocked > /dev/null

# Approve and supply COMP  
cast send $COMP "approve(address,uint256)" $COMET 100000000000000000000 --from $USER2 --rpc-url $RPC --unlocked > /dev/null
cast send $COMET "supply(address,uint256)" $COMP 100000000000000000000 --from $USER2 --rpc-url $RPC --unlocked > /dev/null

echo "User 2 setup complete!"
echo "User 2 address: $USER2"
echo "WETH collateral: 5 ETH"
echo "COMP collateral: 100 COMP"

echo ""
echo "✅ Test accounts ready!"
