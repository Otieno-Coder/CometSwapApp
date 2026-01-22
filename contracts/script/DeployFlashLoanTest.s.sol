// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {FlashLoanTest} from "../src/FlashLoanTest.sol";
import {SepoliaAddresses} from "../src/libraries/Addresses.sol";
import {IPoolAddressesProvider} from "../src/interfaces/aave/IPoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeployFlashLoanTest
 * @notice Deploy FlashLoanTest contract to Sepolia for Phase 1 verification
 *
 * Usage:
 *   forge script script/DeployFlashLoanTest.s.sol:DeployFlashLoanTest \
 *     --rpc-url $SEPOLIA_RPC_URL \
 *     --broadcast \
 *     --verify \
 *     -vvvv
 */
contract DeployFlashLoanTest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("=== Phase 1: Flash Loan Test Deployment ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);

        // Verify Sepolia
        require(block.chainid == SepoliaAddresses.CHAIN_ID, "Not on Sepolia");

        // Verify Pool Address Provider is valid
        address poolProvider = SepoliaAddresses.AAVE_POOL_ADDRESSES_PROVIDER;
        console2.log("Pool Addresses Provider:", poolProvider);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy FlashLoanTest
        FlashLoanTest flashLoanTest = new FlashLoanTest(poolProvider);

        vm.stopBroadcast();

        // Log deployment info
        console2.log("");
        console2.log("=== Deployment Complete ===");
        console2.log("FlashLoanTest deployed at:", address(flashLoanTest));

        // Verify configuration
        address poolAddress = flashLoanTest.getPool();
        uint128 premium = flashLoanTest.getFlashLoanPremium();

        console2.log("");
        console2.log("=== Verification ===");
        console2.log("Aave Pool:", poolAddress);
        console2.log("Flash Loan Premium (basis points):", premium);
        console2.log("Flash Loan Premium (%):", premium * 100 / 10000);

        console2.log("");
        console2.log("=== Next Steps ===");
        console2.log("1. Fund the contract with some WETH for premium payments");
        console2.log("2. Call executeFlashLoan(WETH, amount) to test");
        console2.log("");
        console2.log("WETH address:", SepoliaAddresses.WETH);
        console2.log("USDC address:", SepoliaAddresses.USDC);
    }
}

/**
 * @title ExecuteFlashLoan
 * @notice Script to execute a flash loan on deployed FlashLoanTest
 *
 * Usage:
 *   FLASH_LOAN_TEST=0x... forge script script/DeployFlashLoanTest.s.sol:ExecuteFlashLoan \
 *     --rpc-url $SEPOLIA_RPC_URL \
 *     --broadcast \
 *     -vvvv
 */
contract ExecuteFlashLoan is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address flashLoanTestAddress = vm.envAddress("FLASH_LOAN_TEST");

        console2.log("=== Execute Flash Loan ===");
        console2.log("Deployer:", deployer);
        console2.log("FlashLoanTest:", flashLoanTestAddress);

        FlashLoanTest flashLoanTest = FlashLoanTest(flashLoanTestAddress);

        // Check current state
        address pool = flashLoanTest.getPool();
        console2.log("Aave Pool:", pool);

        // Use WETH for the test
        address asset = SepoliaAddresses.WETH;
        uint256 amount = 0.001 ether; // Very small amount

        // Calculate premium
        uint256 premium = flashLoanTest.calculatePremium(amount);
        console2.log("Flash loan amount:", amount);
        console2.log("Required premium:", premium);

        // Check contract balance
        uint256 contractBalance = IERC20(asset).balanceOf(flashLoanTestAddress);
        console2.log("Contract WETH balance:", contractBalance);

        require(contractBalance >= premium, "Contract needs more WETH for premium");

        vm.startBroadcast(deployerPrivateKey);

        // Execute flash loan
        flashLoanTest.executeFlashLoan(asset, amount);

        vm.stopBroadcast();

        // Check result
        (address lastAsset, uint256 lastAmount, uint256 lastPremium, bool success) =
            flashLoanTest.getLastFlashLoanDetails();

        console2.log("");
        console2.log("=== Flash Loan Result ===");
        console2.log("Success:", success);
        console2.log("Asset:", lastAsset);
        console2.log("Amount:", lastAmount);
        console2.log("Premium paid:", lastPremium);

        if (success) {
            console2.log("");
            console2.log("SUCCESS! Flash loan executed correctly on Sepolia!");
            console2.log("Phase 1 verification complete!");
        }
    }
}

/**
 * @title VerifyAavePool
 * @notice Quick script to verify Aave Pool configuration on Sepolia
 */
contract VerifyAavePool is Script {
    function run() external view {
        console2.log("=== Aave V3 Verification on Sepolia ===");
        console2.log("Chain ID:", block.chainid);

        address poolProvider = SepoliaAddresses.AAVE_POOL_ADDRESSES_PROVIDER;
        console2.log("Pool Addresses Provider:", poolProvider);

        // Try to get the pool address
        try IPoolAddressesProvider(poolProvider).getPool() returns (address pool) {
            console2.log("Pool Address:", pool);
            console2.log("SUCCESS: Aave V3 is available on Sepolia!");
        } catch {
            console2.log("FAILED: Could not get Pool address");
            console2.log("The PoolAddressesProvider may not be deployed or accessible");
        }
    }
}
