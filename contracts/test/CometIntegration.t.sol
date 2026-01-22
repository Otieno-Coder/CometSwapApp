// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MainnetAddresses} from "../src/libraries/Addresses.sol";

/**
 * @title IComet
 * @notice Minimal interface for Compound V3 (Comet) interactions
 */
interface IComet {
    // ============ Supply & Withdraw ============
    function supply(address asset, uint256 amount) external;
    function supplyTo(address dst, address asset, uint256 amount) external;
    function supplyFrom(address from, address dst, address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external;
    function withdrawTo(address to, address asset, uint256 amount) external;
    function withdrawFrom(address src, address to, address asset, uint256 amount) external;

    // ============ Collateral Info ============
    function collateralBalanceOf(address account, address asset) external view returns (uint128);
    function getAssetInfo(uint8 i) external view returns (AssetInfo memory);
    function getAssetInfoByAddress(address asset) external view returns (AssetInfo memory);
    function numAssets() external view returns (uint8);

    // ============ Account Info ============
    function balanceOf(address account) external view returns (uint256);
    function borrowBalanceOf(address account) external view returns (uint256);
    function isLiquidatable(address account) external view returns (bool);
    function isBorrowCollateralized(address account) external view returns (bool);

    // ============ Protocol Info ============
    function baseToken() external view returns (address);
    function baseTokenPriceFeed() external view returns (address);
    function getPrice(address priceFeed) external view returns (uint256);
    function getUtilization() external view returns (uint256);
    function getSupplyRate(uint256 utilization) external view returns (uint64);
    function getBorrowRate(uint256 utilization) external view returns (uint64);

    // ============ Authorization ============
    function allow(address manager, bool isAllowed) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function hasPermission(address owner, address manager) external view returns (bool);

    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }
}

/**
 * @title CometIntegrationTest
 * @notice Tests for Compound V3 (Comet) integration on mainnet fork
 * @dev Run with: forge test --match-contract CometIntegrationTest --fork-url $MAINNET_RPC_URL -vvv
 */
contract CometIntegrationTest is Test {
    // Mainnet addresses
    IComet public comet;
    IERC20 public usdc;
    IERC20 public weth;
    IERC20 public wbtc;
    IERC20 public comp;

    address public testUser;

    // Whale addresses for getting tokens (mainnet)
    address constant USDC_WHALE = 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341; // Circle
    address constant WETH_WHALE = 0x8EB8a3b98659Cce290402893d0123abb75E3ab28; // Lido
    address constant WBTC_WHALE = 0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8;

    function setUp() public {
        // Skip if not on mainnet fork
        if (block.chainid != 1) {
            return;
        }

        // Initialize contracts
        comet = IComet(MainnetAddresses.COMET_USDC);
        usdc = IERC20(MainnetAddresses.USDC);
        weth = IERC20(MainnetAddresses.WETH);
        wbtc = IERC20(MainnetAddresses.WBTC);
        comp = IERC20(MainnetAddresses.COMP);

        testUser = makeAddr("testUser");

        console2.log("=== Comet Integration Test Setup ===");
        console2.log("Comet USDC Market:", address(comet));
        console2.log("Base Token (USDC):", comet.baseToken());
        console2.log("Chain ID:", block.chainid);
    }

    // ============ Protocol Info Tests ============

    function test_fork_getCometInfo() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        console2.log("");
        console2.log("=== Comet Protocol Info ===");

        // Base token info
        address baseToken = comet.baseToken();
        console2.log("Base Token:", baseToken);
        assertEq(baseToken, MainnetAddresses.USDC, "Base token should be USDC");

        // Utilization and rates
        uint256 utilization = comet.getUtilization();
        uint64 supplyRate = comet.getSupplyRate(utilization);
        uint64 borrowRate = comet.getBorrowRate(utilization);

        console2.log("Utilization:", utilization);
        console2.log("Supply Rate (per second):", supplyRate);
        console2.log("Borrow Rate (per second):", borrowRate);

        // APR calculation (rate * seconds per year)
        uint256 supplyAPR = uint256(supplyRate) * 365 days * 100 / 1e18;
        uint256 borrowAPR = uint256(borrowRate) * 365 days * 100 / 1e18;
        console2.log("Supply APR (approx %):", supplyAPR);
        console2.log("Borrow APR (approx %):", borrowAPR);
    }

    function test_fork_getCollateralAssets() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        console2.log("");
        console2.log("=== Comet Collateral Assets ===");

        uint8 numAssets = comet.numAssets();
        console2.log("Number of collateral assets:", numAssets);

        for (uint8 i = 0; i < numAssets; i++) {
            IComet.AssetInfo memory info = comet.getAssetInfo(i);

            console2.log("");
            console2.log("Asset", i, ":", info.asset);
            console2.log("  Borrow Collateral Factor:", info.borrowCollateralFactor);
            console2.log("  Liquidate Collateral Factor:", info.liquidateCollateralFactor);
            console2.log("  Liquidation Factor:", info.liquidationFactor);
            console2.log("  Supply Cap:", info.supplyCap);

            // Get current price
            uint256 price = comet.getPrice(info.priceFeed);
            console2.log("  Price (8 decimals):", price);
        }
    }

    // ============ Supply Collateral Tests ============

    function test_fork_supplyWETHCollateral() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 supplyAmount = 1 ether; // 1 WETH

        console2.log("");
        console2.log("=== Supply WETH Collateral Test ===");

        // Get WETH from whale
        vm.prank(WETH_WHALE);
        weth.transfer(testUser, supplyAmount);

        uint256 userWethBefore = weth.balanceOf(testUser);
        console2.log("User WETH balance before:", userWethBefore);

        // Supply WETH to Comet
        vm.startPrank(testUser);
        weth.approve(address(comet), supplyAmount);
        comet.supply(address(weth), supplyAmount);
        vm.stopPrank();

        // Check results
        uint256 userWethAfter = weth.balanceOf(testUser);
        uint128 collateralBalance = comet.collateralBalanceOf(testUser, address(weth));

        console2.log("User WETH balance after:", userWethAfter);
        console2.log("User WETH collateral in Comet:", collateralBalance);

        assertEq(userWethAfter, 0, "All WETH should be deposited");
        assertEq(collateralBalance, supplyAmount, "Collateral should equal supply amount");

        // Check account status
        bool isCollateralized = comet.isBorrowCollateralized(testUser);
        bool isLiquidatable = comet.isLiquidatable(testUser);

        console2.log("Is borrow collateralized:", isCollateralized);
        console2.log("Is liquidatable:", isLiquidatable);

        assertTrue(isCollateralized, "Should be collateralized");
        assertFalse(isLiquidatable, "Should not be liquidatable");
    }

    function test_fork_withdrawWETHCollateral() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 supplyAmount = 1 ether;

        console2.log("");
        console2.log("=== Withdraw WETH Collateral Test ===");

        // First supply WETH
        vm.prank(WETH_WHALE);
        weth.transfer(testUser, supplyAmount);

        vm.startPrank(testUser);
        weth.approve(address(comet), supplyAmount);
        comet.supply(address(weth), supplyAmount);

        uint128 collateralBefore = comet.collateralBalanceOf(testUser, address(weth));
        console2.log("Collateral before withdraw:", collateralBefore);

        // Withdraw half
        uint256 withdrawAmount = supplyAmount / 2;
        comet.withdraw(address(weth), withdrawAmount);
        vm.stopPrank();

        // Check results
        uint128 collateralAfter = comet.collateralBalanceOf(testUser, address(weth));
        uint256 userWethAfter = weth.balanceOf(testUser);

        console2.log("Collateral after withdraw:", collateralAfter);
        console2.log("User WETH balance after:", userWethAfter);

        assertEq(collateralAfter, supplyAmount - withdrawAmount, "Collateral should decrease");
        assertEq(userWethAfter, withdrawAmount, "User should receive withdrawn WETH");
    }

    // ============ Borrow Tests ============

    function test_fork_supplyCollateralAndBorrow() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 wethSupplyAmount = 10 ether; // 10 WETH
        uint256 usdcBorrowAmount = 5000e6; // 5000 USDC

        console2.log("");
        console2.log("=== Supply Collateral and Borrow Test ===");

        // Get WETH from whale
        vm.prank(WETH_WHALE);
        weth.transfer(testUser, wethSupplyAmount);

        vm.startPrank(testUser);

        // Supply WETH as collateral
        weth.approve(address(comet), wethSupplyAmount);
        comet.supply(address(weth), wethSupplyAmount);

        console2.log("WETH collateral supplied:", wethSupplyAmount);

        // Check borrowing power
        IComet.AssetInfo memory wethInfo = comet.getAssetInfoByAddress(address(weth));
        uint256 wethPrice = comet.getPrice(wethInfo.priceFeed);

        // Calculate max borrow (collateral * price * borrowCF / scale)
        // borrowCollateralFactor is scaled by 1e18
        uint256 collateralValue = (wethSupplyAmount * wethPrice) / 1e18; // In 8 decimal USD
        uint256 maxBorrow = (collateralValue * wethInfo.borrowCollateralFactor) / 1e18;

        console2.log("WETH price (8 decimals):", wethPrice);
        console2.log("Collateral value (8 decimals USD):", collateralValue);
        console2.log("Borrow CF:", wethInfo.borrowCollateralFactor);
        console2.log("Max borrow (8 decimals):", maxBorrow);

        // Borrow USDC
        comet.withdraw(address(usdc), usdcBorrowAmount);

        vm.stopPrank();

        // Check results
        uint256 userUsdcBalance = usdc.balanceOf(testUser);
        uint256 borrowBalance = comet.borrowBalanceOf(testUser);

        console2.log("User USDC balance after borrow:", userUsdcBalance);
        console2.log("Borrow balance:", borrowBalance);

        assertEq(userUsdcBalance, usdcBorrowAmount, "User should receive borrowed USDC");
        assertTrue(borrowBalance >= usdcBorrowAmount, "Borrow balance should be at least borrow amount");

        // Check health
        bool isCollateralized = comet.isBorrowCollateralized(testUser);
        bool isLiquidatable = comet.isLiquidatable(testUser);

        console2.log("Is borrow collateralized:", isCollateralized);
        console2.log("Is liquidatable:", isLiquidatable);

        assertTrue(isCollateralized, "Should still be collateralized");
        assertFalse(isLiquidatable, "Should not be liquidatable");
    }

    // ============ Authorization Tests ============

    function test_fork_allowManagerToWithdraw() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 supplyAmount = 1 ether;
        address manager = makeAddr("manager");

        console2.log("");
        console2.log("=== Allow Manager Test ===");

        // Setup: Supply WETH
        vm.prank(WETH_WHALE);
        weth.transfer(testUser, supplyAmount);

        vm.startPrank(testUser);
        weth.approve(address(comet), supplyAmount);
        comet.supply(address(weth), supplyAmount);

        // Allow manager to manage user's position
        comet.allow(manager, true);
        vm.stopPrank();

        // Verify permission
        bool hasPermission = comet.hasPermission(testUser, manager);
        console2.log("Manager has permission:", hasPermission);
        assertTrue(hasPermission, "Manager should have permission");

        // Check collateral before
        uint128 collateralBefore = comet.collateralBalanceOf(testUser, address(weth));
        console2.log("Collateral before manager withdraw:", collateralBefore);

        // Manager withdraws FROM user's position TO manager's address
        vm.prank(manager);
        comet.withdrawFrom(testUser, manager, address(weth), supplyAmount);

        // Check results
        uint256 managerWeth = weth.balanceOf(manager);
        uint128 userCollateral = comet.collateralBalanceOf(testUser, address(weth));

        console2.log("Manager WETH balance:", managerWeth);
        console2.log("User collateral remaining:", userCollateral);

        assertEq(managerWeth, supplyAmount, "Manager should receive WETH");
        assertEq(userCollateral, 0, "User collateral should be 0");
    }

    // ============ Multiple Collateral Tests ============

    function test_fork_supplyMultipleCollaterals() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 wethAmount = 1 ether;
        uint256 wbtcAmount = 0.1e8; // 0.1 WBTC (8 decimals)

        console2.log("");
        console2.log("=== Supply Multiple Collaterals Test ===");

        // Get tokens from whales
        vm.prank(WETH_WHALE);
        weth.transfer(testUser, wethAmount);

        vm.prank(WBTC_WHALE);
        wbtc.transfer(testUser, wbtcAmount);

        vm.startPrank(testUser);

        // Supply WETH
        weth.approve(address(comet), wethAmount);
        comet.supply(address(weth), wethAmount);

        // Supply WBTC
        wbtc.approve(address(comet), wbtcAmount);
        comet.supply(address(wbtc), wbtcAmount);

        vm.stopPrank();

        // Check balances
        uint128 wethCollateral = comet.collateralBalanceOf(testUser, address(weth));
        uint128 wbtcCollateral = comet.collateralBalanceOf(testUser, address(wbtc));

        console2.log("WETH collateral:", wethCollateral);
        console2.log("WBTC collateral:", wbtcCollateral);

        assertEq(wethCollateral, wethAmount, "WETH collateral should match");
        assertEq(wbtcCollateral, wbtcAmount, "WBTC collateral should match");

        // Check combined health
        bool isCollateralized = comet.isBorrowCollateralized(testUser);
        console2.log("Is collateralized with multiple assets:", isCollateralized);
        assertTrue(isCollateralized, "Should be collateralized");
    }
}
