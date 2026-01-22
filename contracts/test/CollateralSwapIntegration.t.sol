// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {CollateralSwap} from "../src/CollateralSwap.sol";
import {MainnetAddresses} from "../src/libraries/Addresses.sol";
import {IComet} from "../src/interfaces/compound/IComet.sol";
import {IPool} from "../src/interfaces/aave/IPool.sol";
import {IPoolAddressesProvider} from "../src/interfaces/aave/IPoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title CollateralSwapIntegrationTest
 * @notice Full integration tests for CollateralSwap on mainnet fork
 * @dev Run with: forge test --match-contract CollateralSwapIntegrationTest --fork-url $MAINNET_RPC_URL -vvv
 */
contract CollateralSwapIntegrationTest is Test {
    CollateralSwap public collateralSwap;
    IComet public comet;
    IPool public aavePool;

    IERC20 public weth;
    IERC20 public wbtc;
    IERC20 public usdc;
    IERC20 public comp;

    address public deployer;
    address public user;

    // Whale addresses for getting test tokens
    address constant WETH_WHALE = 0x8EB8a3b98659Cce290402893d0123abb75E3ab28;
    address constant WBTC_WHALE = 0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8;
    address constant USDC_WHALE = 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341;

    // Fee tiers
    uint24 constant FEE_MEDIUM = 3000; // 0.3%

    function setUp() public {
        if (block.chainid != 1) {
            return;
        }

        deployer = makeAddr("deployer");
        user = makeAddr("user");

        // Initialize contracts
        comet = IComet(MainnetAddresses.COMET_USDC);
        weth = IERC20(MainnetAddresses.WETH);
        wbtc = IERC20(MainnetAddresses.WBTC);
        usdc = IERC20(MainnetAddresses.USDC);
        comp = IERC20(MainnetAddresses.COMP);

        // Get Aave Pool
        IPoolAddressesProvider provider = IPoolAddressesProvider(MainnetAddresses.AAVE_POOL_ADDRESSES_PROVIDER);
        aavePool = IPool(provider.getPool());

        // Deploy CollateralSwap
        vm.prank(deployer);
        collateralSwap = new CollateralSwap(
            MainnetAddresses.AAVE_POOL_ADDRESSES_PROVIDER,
            MainnetAddresses.COMET_USDC,
            MainnetAddresses.UNISWAP_SWAP_ROUTER_02,
            deployer
        );

        // Setup: Add supported collaterals
        vm.startPrank(deployer);
        collateralSwap.addCollateral(address(weth));
        collateralSwap.addCollateral(address(wbtc));
        collateralSwap.addCollateral(address(comp));
        vm.stopPrank();

        console2.log("=== CollateralSwap Integration Test Setup ===");
        console2.log("CollateralSwap:", address(collateralSwap));
        console2.log("Comet:", address(comet));
        console2.log("Aave Pool:", address(aavePool));
        console2.log("Chain ID:", block.chainid);
    }

    // ============ Setup Verification Tests ============

    function test_fork_setup() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        console2.log("");
        console2.log("=== Setup Verification ===");

        // Verify contract configuration
        assertEq(address(collateralSwap.comet()), address(comet), "Comet mismatch");
        assertEq(address(collateralSwap.swapRouter()), MainnetAddresses.UNISWAP_SWAP_ROUTER_02, "SwapRouter mismatch");

        // Verify collaterals are added
        assertTrue(collateralSwap.isCollateralSupported(address(weth)), "WETH should be supported");
        assertTrue(collateralSwap.isCollateralSupported(address(wbtc)), "WBTC should be supported");
        assertTrue(collateralSwap.isCollateralSupported(address(comp)), "COMP should be supported");

        // Verify flash loan premium
        uint128 premium = collateralSwap.getFlashLoanPremium();
        console2.log("Flash loan premium (bps):", premium);
        assertTrue(premium > 0, "Premium should be > 0");

        console2.log("Setup verified successfully!");
    }

    // ============ User Setup Helper ============

    function _setupUserWithWETHCollateral(uint256 wethAmount) internal {
        // Transfer WETH to user
        vm.prank(WETH_WHALE);
        weth.transfer(user, wethAmount);

        // User supplies WETH to Comet
        vm.startPrank(user);
        weth.approve(address(comet), wethAmount);
        comet.supply(address(weth), wethAmount);

        // User allows CollateralSwap to manage their position
        comet.allow(address(collateralSwap), true);
        vm.stopPrank();

        console2.log("User WETH collateral setup:", wethAmount);
    }

    function _setupUserWithWBTCCollateral(uint256 wbtcAmount) internal {
        // Transfer WBTC to user
        vm.prank(WBTC_WHALE);
        wbtc.transfer(user, wbtcAmount);

        // User supplies WBTC to Comet
        vm.startPrank(user);
        wbtc.approve(address(comet), wbtcAmount);
        comet.supply(address(wbtc), wbtcAmount);

        // User allows CollateralSwap to manage their position
        comet.allow(address(collateralSwap), true);
        vm.stopPrank();

        console2.log("User WBTC collateral setup:", wbtcAmount);
    }

    // ============ Full Swap Tests ============

    function test_fork_swapWETHtoWBTC() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        console2.log("");
        console2.log("=== Swap WETH -> WBTC Test ===");

        // Setup: User has 10 WETH as collateral
        uint256 initialWeth = 10 ether;
        _setupUserWithWETHCollateral(initialWeth);

        // User wants to swap 5 WETH to WBTC
        uint256 swapAmount = 5 ether;

        // Check initial state
        uint128 wethBefore = comet.collateralBalanceOf(user, address(weth));
        uint128 wbtcBefore = comet.collateralBalanceOf(user, address(wbtc));

        console2.log("Before swap:");
        console2.log("  WETH collateral:", wethBefore);
        console2.log("  WBTC collateral:", wbtcBefore);

        // Calculate minimum expected WBTC
        // At ~$2900/ETH and ~$88000/BTC, 5 ETH ≈ 0.165 BTC
        // With slippage, expect at least 0.15 BTC
        uint256 minWbtc = 0.15e8; // 0.15 WBTC

        // Execute swap
        vm.prank(user);
        collateralSwap.swapCollateral(
            address(weth), // source
            address(wbtc), // target
            swapAmount, // amount
            minWbtc, // min target
            FEE_MEDIUM // fee tier
        );

        // Check final state
        uint128 wethAfter = comet.collateralBalanceOf(user, address(weth));
        uint128 wbtcAfter = comet.collateralBalanceOf(user, address(wbtc));

        console2.log("After swap:");
        console2.log("  WETH collateral:", wethAfter);
        console2.log("  WBTC collateral:", wbtcAfter);
        console2.log("  WETH used:", wethBefore - wethAfter);
        console2.log("  WBTC received:", wbtcAfter - wbtcBefore);

        // Verify swap executed correctly
        assertEq(wethAfter, wethBefore - swapAmount, "WETH should decrease by swap amount");
        assertTrue(wbtcAfter >= minWbtc, "Should receive at least minimum WBTC");

        // Verify user is still healthy
        bool isLiquidatable = comet.isLiquidatable(user);
        assertFalse(isLiquidatable, "User should not be liquidatable after swap");

        console2.log("Swap completed successfully!");
    }

    function test_fork_swapWBTCtoWETH() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        console2.log("");
        console2.log("=== Swap WBTC -> WETH Test ===");

        // Setup: User has 0.5 WBTC as collateral
        uint256 initialWbtc = 0.5e8; // 0.5 WBTC
        _setupUserWithWBTCCollateral(initialWbtc);

        // User wants to swap 0.2 WBTC to WETH
        uint256 swapAmount = 0.2e8;

        // Check initial state
        uint128 wbtcBefore = comet.collateralBalanceOf(user, address(wbtc));
        uint128 wethBefore = comet.collateralBalanceOf(user, address(weth));

        console2.log("Before swap:");
        console2.log("  WBTC collateral:", wbtcBefore);
        console2.log("  WETH collateral:", wethBefore);

        // Calculate minimum expected WETH
        // 0.2 BTC at ~$88000 = $17600
        // At ~$2900/ETH = ~6 ETH
        // With slippage, expect at least 5 ETH
        uint256 minWeth = 5 ether;

        // Execute swap
        vm.prank(user);
        collateralSwap.swapCollateral(
            address(wbtc), // source
            address(weth), // target
            swapAmount, // amount
            minWeth, // min target
            FEE_MEDIUM // fee tier
        );

        // Check final state
        uint128 wbtcAfter = comet.collateralBalanceOf(user, address(wbtc));
        uint128 wethAfter = comet.collateralBalanceOf(user, address(weth));

        console2.log("After swap:");
        console2.log("  WBTC collateral:", wbtcAfter);
        console2.log("  WETH collateral:", wethAfter);
        console2.log("  WBTC used:", wbtcBefore - wbtcAfter);
        console2.log("  WETH received:", wethAfter - wethBefore);

        // Verify
        assertEq(wbtcAfter, wbtcBefore - swapAmount, "WBTC should decrease by swap amount");
        assertTrue(wethAfter >= minWeth, "Should receive at least minimum WETH");

        console2.log("Swap completed successfully!");
    }

    // ============ Error Cases ============

    function test_fork_revertOnInsufficientCollateral() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        console2.log("");
        console2.log("=== Insufficient Collateral Test ===");

        // Setup: User has 1 WETH as collateral
        _setupUserWithWETHCollateral(1 ether);

        // Try to swap more than user has
        vm.prank(user);
        vm.expectRevert();
        collateralSwap.swapCollateral(
            address(weth),
            address(wbtc),
            10 ether, // More than user has
            0.1e8,
            FEE_MEDIUM
        );

        console2.log("Correctly reverted on insufficient collateral");
    }

    function test_fork_revertOnUnsupportedCollateral() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        console2.log("");
        console2.log("=== Unsupported Collateral Test ===");

        // Try to swap with unsupported asset
        vm.prank(user);
        vm.expectRevert();
        collateralSwap.swapCollateral(
            address(usdc), // Not a supported collateral
            address(wbtc),
            1000e6,
            0.01e8,
            FEE_MEDIUM
        );

        console2.log("Correctly reverted on unsupported collateral");
    }

    function test_fork_revertOnSameAsset() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        console2.log("");
        console2.log("=== Same Asset Test ===");

        _setupUserWithWETHCollateral(1 ether);

        // Try to swap WETH to WETH
        vm.prank(user);
        vm.expectRevert();
        collateralSwap.swapCollateral(
            address(weth),
            address(weth), // Same asset
            0.5 ether,
            0.5 ether,
            FEE_MEDIUM
        );

        console2.log("Correctly reverted on same asset swap");
    }

    function test_fork_revertWithoutAuthorization() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        console2.log("");
        console2.log("=== Authorization Test ===");

        // Transfer WETH to user
        vm.prank(WETH_WHALE);
        weth.transfer(user, 1 ether);

        // User supplies WETH but does NOT allow CollateralSwap
        vm.startPrank(user);
        weth.approve(address(comet), 1 ether);
        comet.supply(address(weth), 1 ether);
        // Note: NOT calling comet.allow(address(collateralSwap), true);
        vm.stopPrank();

        // Try to swap - should fail because CollateralSwap can't withdraw
        vm.prank(user);
        vm.expectRevert();
        collateralSwap.swapCollateral(
            address(weth),
            address(wbtc),
            0.5 ether,
            0.01e8,
            FEE_MEDIUM
        );

        console2.log("Correctly reverted without authorization");
    }

    // ============ Admin Tests ============

    function test_fork_adminCanAddRemoveCollateral() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        console2.log("");
        console2.log("=== Admin Add/Remove Collateral Test ===");

        // Remove COMP support
        vm.prank(deployer);
        collateralSwap.removeCollateral(address(comp));
        assertFalse(collateralSwap.isCollateralSupported(address(comp)), "COMP should be removed");

        // Re-add COMP support
        vm.prank(deployer);
        collateralSwap.addCollateral(address(comp));
        assertTrue(collateralSwap.isCollateralSupported(address(comp)), "COMP should be added");

        console2.log("Admin collateral management works correctly");
    }

    function test_fork_nonAdminCannotAddCollateral() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        console2.log("");
        console2.log("=== Non-Admin Add Collateral Test ===");

        // Non-admin tries to add collateral
        vm.prank(user);
        vm.expectRevert();
        collateralSwap.addCollateral(address(usdc));

        console2.log("Correctly reverted for non-admin");
    }
}
