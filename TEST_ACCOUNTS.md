# 🧪 Test Accounts Setup

## Local Fork Deployment

**CollateralSwap Contract:** `0x8b941d833A740bcFd9Cee5B873FFbB8EbAdA6EF0`  
**Network:** Local Anvil Fork (http://127.0.0.1:8545)  
**Chain ID:** 1 (Mainnet fork)

## Anvil Default Accounts

These accounts come pre-funded with 10,000 ETH each on Anvil:

### Account #0 (Deployer)
- **Address:** `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- **Private Key:** `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
- **Balance:** 10,000 ETH
- **Status:** Used to deploy CollateralSwap

### Account #1 (Test User 1)
- **Address:** `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
- **Private Key:** `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d`
- **Balance:** 10,000 ETH
- **Status:** Ready for setup

### Account #2 (Test User 2)
- **Address:** `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`
- **Private Key:** `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a`
- **Balance:** 10,000 ETH
- **Status:** Ready for setup

## Setting Up Test Accounts

### Option 1: Using Foundry Script

```bash
cd contracts
ETHERSCAN_API_KEY=dummy forge script script/SetupTestAccounts.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast -vv
```

### Option 2: Manual Setup via Frontend

1. **Connect Wallet** to local network (http://127.0.0.1:8545, Chain ID 1)
2. **Import Account #1** using private key above
3. **Get Test Tokens:**
   - Use a faucet or swap ETH for tokens on Uniswap
   - Or use `cast` commands to give tokens (see below)

### Option 3: Using Cast Commands

```bash
# Give User 1 some WETH (if you have a WETH holder address)
cast rpc anvil_impersonateAccount <WETH_WHALE_ADDRESS> --rpc-url http://127.0.0.1:8545
cast send 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 \
  "transfer(address,uint256)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  10000000000000000000 \
  --from <WETH_WHALE_ADDRESS> \
  --rpc-url http://127.0.0.1:8545 \
  --unlocked

# Then supply to Comet
cast send 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 \
  "approve(address,uint256)" \
  0xc3d688B66703497DAA19211EEdff47f25384cdc3 \
  10000000000000000000 \
  --from 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

cast send 0xc3d688B66703497DAA19211EEdff47f25384cdc3 \
  "supply(address,uint256)" \
  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 \
  10000000000000000000 \
  --from 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

## Testing the Swap

Once you have collateral set up:

1. **Approve CollateralSwap** to manage your Comet position:
   ```bash
   cast send 0xc3d688B66703497DAA19211EEdff47f25384cdc3 \
     "allow(address,bool)" \
     0x8b941d833A740bcFd9Cee5B873FFbB8EbAdA6EF0 \
     true \
     --from <YOUR_ACCOUNT> \
     --rpc-url http://127.0.0.1:8545 \
     --private-key <YOUR_KEY>
   ```

2. **Use the Frontend:**
   - Connect wallet to local network
   - Select tokens to swap
   - Execute swap!

## Quick Test Commands

```bash
# Check collateral balance
cast call 0xc3d688B66703497DAA19211EEdff47f25384cdc3 \
  "collateralBalanceOf(address,address)(uint128)" \
  <USER_ADDRESS> \
  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 \
  --rpc-url http://127.0.0.1:8545

# Check if CollateralSwap is allowed
cast call 0xc3d688B66703497DAA19211EEdff47f25384cdc3 \
  "isAllowed(address,address)(bool)" \
  <USER_ADDRESS> \
  0x8b941d833A740bcFd9Cee5B873FFbB8EbAdA6EF0 \
  --rpc-url http://127.0.0.1:8545
```

## Notes

- All accounts start with 10,000 ETH on Anvil
- You can impersonate any mainnet address using `anvil_impersonateAccount`
- The fork has access to all mainnet state, so you can interact with real contracts
- Gas is free on the local fork!
