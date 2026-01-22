// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {CollateralSwap} from "../src/CollateralSwap.sol";
import {SepoliaAddresses} from "../src/libraries/Addresses.sol";

/**
 * @title DeployCollateralSwap
 * @notice Deployment script for CollateralSwap contract on Sepolia
 *
 * Usage:
 *   forge script script/Deploy.s.sol:DeployCollateralSwap \
 *     --rpc-url $SEPOLIA_RPC_URL \
 *     --broadcast \
 *     --verify \
 *     -vvvv
 */
contract DeployCollateralSwap is Script {
    function run() external {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("=== CometSwap Deployment ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);

        // Verify we're on Sepolia
        require(block.chainid == SepoliaAddresses.CHAIN_ID, "Not on Sepolia");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy CollateralSwap for USDC market
        CollateralSwap collateralSwap = new CollateralSwap(
            SepoliaAddresses.AAVE_POOL_ADDRESSES_PROVIDER,
            SepoliaAddresses.COMET_USDC, // Use USDC market
            SepoliaAddresses.UNISWAP_SWAP_ROUTER_02,
            deployer // owner
        );

        console2.log("CollateralSwap deployed at:", address(collateralSwap));

        // Add supported collaterals (WETH for now, as we have verified addresses)
        collateralSwap.addCollateral(SepoliaAddresses.WETH);
        console2.log("Added WETH as supported collateral");

        // Note: USDC is the base asset, not collateral in the USDC market
        // Add other collaterals once we verify their addresses (WBTC, COMP)

        vm.stopBroadcast();

        // Log deployment info
        console2.log("");
        console2.log("=== Deployment Summary ===");
        console2.log("CollateralSwap:", address(collateralSwap));
        console2.log("Owner:", deployer);
        console2.log("Comet (USDC):", SepoliaAddresses.COMET_USDC);
        console2.log("Aave Pool Provider:", SepoliaAddresses.AAVE_POOL_ADDRESSES_PROVIDER);
        console2.log("Uniswap Router:", SepoliaAddresses.UNISWAP_SWAP_ROUTER_02);
        console2.log("");
        console2.log("=== Supported Collaterals ===");
        console2.log("WETH:", SepoliaAddresses.WETH);
    }
}

/**
 * @title VerifyAddresses
 * @notice Script to verify and display all addresses on Sepolia
 */
contract VerifyAddresses is Script {
    function run() external view {
        console2.log("=== Sepolia Address Verification ===");
        console2.log("Chain ID:", block.chainid);
        console2.log("");

        console2.log("=== Compound V3 (Comet) ===");
        console2.log("USDC Market (cUSDCv3):", SepoliaAddresses.COMET_USDC);
        console2.log("WETH Market (cWETHv3):", SepoliaAddresses.COMET_WETH);
        console2.log("Configurator:", SepoliaAddresses.COMET_CONFIGURATOR);
        console2.log("Rewards:", SepoliaAddresses.COMET_REWARDS);
        console2.log("Bulker (USDC):", SepoliaAddresses.COMET_BULKER);
        console2.log("Fauceteer:", SepoliaAddresses.COMET_FAUCETEER);
        console2.log("");

        console2.log("=== Uniswap V3 ===");
        console2.log("Factory:", SepoliaAddresses.UNISWAP_V3_FACTORY);
        console2.log("SwapRouter02:", SepoliaAddresses.UNISWAP_SWAP_ROUTER_02);
        console2.log("QuoterV2:", SepoliaAddresses.UNISWAP_QUOTER_V2);
        console2.log("");

        console2.log("=== Aave V3 ===");
        console2.log("PoolAddressesProvider:", SepoliaAddresses.AAVE_POOL_ADDRESSES_PROVIDER);
        console2.log("");

        console2.log("=== Tokens ===");
        console2.log("USDC:", SepoliaAddresses.USDC);
        console2.log("WETH:", SepoliaAddresses.WETH);
        console2.log("");

        console2.log("=== Price Feeds ===");
        console2.log("USDC/USD:", SepoliaAddresses.USDC_USD_FEED);
        console2.log("ETH/USD:", SepoliaAddresses.ETH_USD_FEED);
        console2.log("BTC/USD:", SepoliaAddresses.BTC_USD_FEED);
        console2.log("COMP/USD:", SepoliaAddresses.COMP_USD_FEED);
    }
}

/**
 * @title GetTestTokens
 * @notice Script to get test tokens from Comet Fauceteer
 */
contract GetTestTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Getting test tokens for:", deployer);
        console2.log("Fauceteer:", SepoliaAddresses.COMET_FAUCETEER);
        console2.log("");
        console2.log("Note: Interact with Fauceteer directly on Etherscan:");
        console2.log("https://sepolia.etherscan.io/address/0x68793eA49297eB75DFB4610B68e076D2A5c7646C#writeContract");
    }
}
