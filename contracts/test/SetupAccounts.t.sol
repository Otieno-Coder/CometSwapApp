// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IComet} from "../src/interfaces/compound/IComet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MainnetAddresses} from "../src/libraries/Addresses.sol";

/**
 * @title SetupAccountsTest
 * @notice Sets up test accounts - run this once to prepare accounts for testing
 * 
 * Usage:
 *   forge test --match-test test_setupAccounts --fork-url http://127.0.0.1:8545 -vv
 */
contract SetupAccountsTest is Test {
    IComet public comet = IComet(MainnetAddresses.COMET_USDC);
    
    address public user1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public user2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    
    address public constant WETH = MainnetAddresses.WETH;
    address public constant COMP = MainnetAddresses.COMP;
    
    function test_setupAccounts() public {
        console2.log("=== Setting Up Test Accounts ===");
        
        // Setup User 1: 10 WETH
        deal(WETH, user1, 10 ether);
        vm.startPrank(user1);
        IERC20(WETH).approve(address(comet), 10 ether);
        comet.supply(WETH, 10 ether);
        vm.stopPrank();
        
        uint128 user1WETH = comet.collateralBalanceOf(user1, WETH);
        console2.log("User 1 WETH collateral:", user1WETH);
        assertTrue(user1WETH > 0, "User 1 should have WETH collateral");
        
        // Setup User 2: 5 WETH + 100 COMP
        deal(WETH, user2, 5 ether);
        deal(COMP, user2, 100 * 10**18);
        
        vm.startPrank(user2);
        IERC20(WETH).approve(address(comet), 5 ether);
        comet.supply(WETH, 5 ether);
        
        IERC20(COMP).approve(address(comet), 100 * 10**18);
        comet.supply(COMP, 100 * 10**18);
        vm.stopPrank();
        
        uint128 user2WETH = comet.collateralBalanceOf(user2, WETH);
        uint128 user2COMP = comet.collateralBalanceOf(user2, COMP);
        console2.log("User 2 WETH collateral:", user2WETH);
        console2.log("User 2 COMP collateral:", user2COMP);
        assertTrue(user2WETH > 0, "User 2 should have WETH collateral");
        assertTrue(user2COMP > 0, "User 2 should have COMP collateral");
        
        console2.log("");
        console2.log("=== Setup Complete ===");
        console2.log("User 1:", user1);
        console2.log("User 2:", user2);
        console2.log("Ready for testing!");
    }
}
