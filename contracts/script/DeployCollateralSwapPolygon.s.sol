// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {CollateralSwap} from "../src/CollateralSwap.sol";
import {PolygonAddresses} from "../src/libraries/Addresses.sol";

/**
 * @title DeployCollateralSwapPolygon
 * @notice Deployment script for CollateralSwap contract on Polygon
 *
 * Usage (Polygon mainnet fork):
 *   anvil --fork-url $POLYGON_RPC_URL --chain-id 137 --port 9547
 *   forge script script/DeployCollateralSwapPolygon.s.sol:DeployCollateralSwapPolygonFork \
 *     --rpc-url http://127.0.0.1:9547 --broadcast -vvvv
 */
contract DeployCollateralSwapPolygon is Script {
    // Supported collateral assets (Polygon USDC market)
    address[] public collaterals;

    function setUp() public {
        // Initialize supported collaterals from Polygon Comet config
        collaterals.push(PolygonAddresses.WETH);
        collaterals.push(PolygonAddresses.WBTC);
        collaterals.push(PolygonAddresses.WMATIC);
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

        console2.log("=== CollateralSwap Polygon Deployment ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("");

        require(block.chainid == PolygonAddresses.CHAIN_ID, "Not on Polygon");

        // Log addresses being used
        console2.log("--- Protocol Addresses ---");
        console2.log("Aave Pool Provider:", PolygonAddresses.AAVE_POOL_ADDRESSES_PROVIDER);
        console2.log("Comet USDC Market:", PolygonAddresses.COMET_USDC);
        console2.log("Uniswap Router:", PolygonAddresses.UNISWAP_SWAP_ROUTER_02);
        console2.log("");

        if (deployerPrivateKey != 0) {
            vm.startBroadcast(deployerPrivateKey);
        } else {
            vm.startBroadcast();
        }

        // Deploy CollateralSwap
        CollateralSwap collateralSwap = new CollateralSwap(
            PolygonAddresses.AAVE_POOL_ADDRESSES_PROVIDER,
            PolygonAddresses.COMET_USDC,
            PolygonAddresses.UNISWAP_SWAP_ROUTER_02,
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
        console2.log("Polygon COLLATERAL_SWAP:", address(collateralSwap));
    }
}

contract DeployCollateralSwapPolygonFork is Script {
    function run() public {
        // Use anvil's default account for testing
        uint256 deployerPrivateKey =
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("=== Polygon Fork Deployment Test ===");
        console2.log("Deployer:", deployer);
        console2.log("Deployer Balance:", deployer.balance / 1e18, "MATIC");
        console2.log("Chain ID:", block.chainid);

        require(block.chainid == PolygonAddresses.CHAIN_ID, "Not on Polygon");

        vm.startBroadcast(deployerPrivateKey);

        CollateralSwap collateralSwap = new CollateralSwap(
            PolygonAddresses.AAVE_POOL_ADDRESSES_PROVIDER,
            PolygonAddresses.COMET_USDC,
            PolygonAddresses.UNISWAP_SWAP_ROUTER_02,
            deployer
        );

        address[] memory collaterals = new address[](3);
        collaterals[0] = PolygonAddresses.WETH;
        collaterals[1] = PolygonAddresses.WBTC;
        collaterals[2] = PolygonAddresses.WMATIC;
        collateralSwap.addCollaterals(collaterals);

        vm.stopBroadcast();

        console2.log("");
        console2.log("=== Deployed Successfully on Polygon Fork ===");
        console2.log("CollateralSwap:", address(collateralSwap));
        console2.log("Supported Collaterals:", collateralSwap.getSupportedCollaterals().length);
    }
}

