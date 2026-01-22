// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {IComet} from "../src/interfaces/compound/IComet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {MainnetAddresses} from "../src/libraries/Addresses.sol";

/**
 * @title SetupTestAccounts
 * @notice Sets up test accounts with tokens and Comet positions for testing
 * 
 * Usage:
 *   forge script script/SetupTestAccounts.s.sol --rpc-url http://localhost:8545 --broadcast -vvvv
 */
contract SetupTestAccounts is Script, Test {
    IComet public comet = IComet(MainnetAddresses.COMET_USDC);
    
    // Test user addresses (Anvil default accounts)
    address public testUser1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Account #1
    address public testUser2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Account #2
    
    // Token addresses
    address public constant WETH = MainnetAddresses.WETH;
    address public constant WBTC = MainnetAddresses.WBTC;
    address public constant COMP = MainnetAddresses.COMP;
    address public constant USDC = MainnetAddresses.USDC;
    
    function run() public {
        console2.log("=== Setting Up Test Accounts ===");
        console2.log("Comet:", address(comet));
        console2.log("");
        
        // Setup User 1: WETH collateral + borrow USDC
        console2.log("--- Setting up User 1 (WETH collateral + borrow) ---");
        setupUser1();
        
        // Setup User 2: WBTC + COMP collateral
        console2.log("");
        console2.log("--- Setting up User 2 (WBTC + COMP collateral) ---");
        setupUser2();
        
        // Print summary
        console2.log("");
        console2.log("=== Setup Complete ===");
        console2.log("User 1:", testUser1);
        console2.log("  WETH Collateral:", comet.collateralBalanceOf(testUser1, WETH));
        console2.log("  Borrow Balance:", comet.borrowBalanceOf(testUser1));
        console2.log("");
        console2.log("User 2:", testUser2);
        console2.log("  WBTC Collateral:", comet.collateralBalanceOf(testUser2, WBTC));
        console2.log("  COMP Collateral:", comet.collateralBalanceOf(testUser2, COMP));
        console2.log("");
        console2.log("You can now test swaps with these accounts!");
    }
    
    function setupUser1() internal {
        // Give user WETH
        uint256 wethAmount = 10 ether;
        deal(WETH, testUser1, wethAmount);
        console2.log("Gave User 1:", wethAmount / 1e18, "WETH");
        
        // Broadcast as user to supply WETH
        vm.broadcast(testUser1);
        IERC20(WETH).approve(address(comet), wethAmount);
        
        vm.broadcast(testUser1);
        comet.supply(WETH, wethAmount);
        console2.log("Supplied WETH to Comet");
        console2.log("User 1 now has WETH collateral - ready for swaps!");
    }
    
    function setupUser2() internal {
        // Give user more WETH and COMP (WETH works reliably)
        uint256 wethAmount = 5 ether;
        uint256 compAmount = 100 * 10**18; // 100 COMP
        
        deal(WETH, testUser2, wethAmount);
        deal(COMP, testUser2, compAmount);
        console2.log("Gave User 2:", wethAmount / 1e18, "WETH");
        console2.log("Gave User 2:", compAmount / 1e18, "COMP");
        
        // Broadcast as user to supply both
        vm.broadcast(testUser2);
        IERC20(WETH).approve(address(comet), wethAmount);
        
        vm.broadcast(testUser2);
        IERC20(COMP).approve(address(comet), compAmount);
        
        vm.broadcast(testUser2);
        comet.supply(WETH, wethAmount);
        console2.log("Supplied WETH to Comet");
        
        vm.broadcast(testUser2);
        comet.supply(COMP, compAmount);
        console2.log("Supplied COMP to Comet");
        console2.log("User 2 now has WETH + COMP collateral - ready for swaps!");
    }
}
