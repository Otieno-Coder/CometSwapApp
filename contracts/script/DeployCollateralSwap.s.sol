// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {CollateralSwap} from "../src/CollateralSwap.sol";
import {MainnetAddresses} from "../src/libraries/Addresses.sol";

/**
 * @title DeployCollateralSwap
 * @notice Deployment script for CollateralSwap contract
 * 
 * Usage:
 *   # Deploy to mainnet fork (dry run)
 *   forge script script/DeployCollateralSwap.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify -vvvv
 * 
 *   # Deploy to mainnet (REAL - use with caution!)
 *   forge script script/DeployCollateralSwap.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify --private-key $DEPLOYER_PRIVATE_KEY -vvvv
 */
contract DeployCollateralSwap is Script {
    // Supported collateral assets (mainnet)
    address[] public collaterals;

    function setUp() public {
        // Initialize supported collaterals
        collaterals.push(MainnetAddresses.WETH);
        collaterals.push(MainnetAddresses.WBTC);
        collaterals.push(MainnetAddresses.COMP);
        collaterals.push(MainnetAddresses.UNI);
        collaterals.push(MainnetAddresses.LINK);
    }

    function run() public {
        // Get deployer from environment or use default for testing
        uint256 deployerPrivateKey = vm.envOr("DEPLOYER_PRIVATE_KEY", uint256(0));
        address deployer;

        if (deployerPrivateKey != 0) {
            deployer = vm.addr(deployerPrivateKey);
        } else {
            // Use a default address for dry runs
            deployer = address(0x1234567890123456789012345678901234567890);
            console2.log("WARNING: No DEPLOYER_PRIVATE_KEY set, using mock address for dry run");
        }

        console2.log("=== CollateralSwap Deployment ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("");

        // Log addresses being used
        console2.log("--- Protocol Addresses ---");
        console2.log("Aave Pool Provider:", MainnetAddresses.AAVE_POOL_ADDRESSES_PROVIDER);
        console2.log("Comet USDC Market:", MainnetAddresses.COMET_USDC);
        console2.log("Uniswap Router:", MainnetAddresses.UNISWAP_SWAP_ROUTER_02);
        console2.log("");

        // Start broadcasting transactions
        if (deployerPrivateKey != 0) {
            vm.startBroadcast(deployerPrivateKey);
        } else {
            vm.startBroadcast();
        }

        // Deploy CollateralSwap
        CollateralSwap collateralSwap = new CollateralSwap(
            MainnetAddresses.AAVE_POOL_ADDRESSES_PROVIDER,
            MainnetAddresses.COMET_USDC,
            MainnetAddresses.UNISWAP_SWAP_ROUTER_02,
            deployer // Owner
        );

        console2.log("CollateralSwap deployed at:", address(collateralSwap));

        // Add supported collaterals
        console2.log("");
        console2.log("--- Adding Supported Collaterals ---");
        collateralSwap.addCollaterals(collaterals);

        for (uint256 i = 0; i < collaterals.length; i++) {
            console2.log("Added collateral:", collaterals[i]);
        }

        vm.stopBroadcast();

        // Verification summary
        console2.log("");
        console2.log("=== Deployment Summary ===");
        console2.log("CollateralSwap:", address(collateralSwap));
        console2.log("Owner:", collateralSwap.owner());
        console2.log("Comet:", address(collateralSwap.comet()));
        console2.log("SwapRouter:", address(collateralSwap.swapRouter()));
        console2.log("Flash Loan Premium:", collateralSwap.getFlashLoanPremium(), "bps");
        console2.log("Supported Collaterals:", collateralSwap.getSupportedCollaterals().length);
        console2.log("");
        console2.log("=== IMPORTANT: Update frontend/src/config/contracts.ts ===");
        console2.log("COLLATERAL_SWAP:", address(collateralSwap));
    }
}

/**
 * @title DeployCollateralSwapFork
 * @notice Deployment script for testing on a local mainnet fork
 * 
 * Usage:
 *   # Start anvil fork first: anvil --fork-url $MAINNET_RPC_URL
 *   # Then deploy:
 *   forge script script/DeployCollateralSwap.s.sol:DeployCollateralSwapFork --rpc-url http://localhost:8545 --broadcast -vvvv
 */
contract DeployCollateralSwapFork is Script {
    function run() public {
        // Use anvil's default account for testing
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("=== Fork Deployment Test ===");
        console2.log("Deployer:", deployer);
        console2.log("Deployer Balance:", deployer.balance / 1e18, "ETH");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy
        CollateralSwap collateralSwap = new CollateralSwap(
            MainnetAddresses.AAVE_POOL_ADDRESSES_PROVIDER,
            MainnetAddresses.COMET_USDC,
            MainnetAddresses.UNISWAP_SWAP_ROUTER_02,
            deployer
        );

        // Add collaterals
        address[] memory collaterals = new address[](5);
        collaterals[0] = MainnetAddresses.WETH;
        collaterals[1] = MainnetAddresses.WBTC;
        collaterals[2] = MainnetAddresses.COMP;
        collaterals[3] = MainnetAddresses.UNI;
        collaterals[4] = MainnetAddresses.LINK;
        collateralSwap.addCollaterals(collaterals);

        vm.stopBroadcast();

        console2.log("");
        console2.log("=== Deployed Successfully ===");
        console2.log("CollateralSwap:", address(collateralSwap));
        console2.log("Supported Collaterals:", collateralSwap.getSupportedCollaterals().length);
    }
}
