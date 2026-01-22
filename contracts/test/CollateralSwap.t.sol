// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {CollateralSwap} from "../src/CollateralSwap.sol";
import {SepoliaAddresses} from "../src/libraries/Addresses.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title CollateralSwapTest
 * @notice Unit tests for CollateralSwap contract
 */
contract CollateralSwapTest is Test {
    CollateralSwap public collateralSwap;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    // Mock addresses for testing (will be replaced with real ones when testing on fork)
    address public mockComet = makeAddr("comet");
    address public mockPoolProvider = makeAddr("poolProvider");
    address public mockSwapRouter = makeAddr("swapRouter");
    address public mockWETH = makeAddr("weth");
    address public mockUSDC = makeAddr("usdc");

    function setUp() public {
        vm.startPrank(owner);

        // For unit tests, we'll use mock addresses
        // For integration tests, we'll fork Sepolia and use real addresses

        // Note: This will fail with mocks because the constructor calls getPool()
        // We'll need to either mock the call or use a fork for proper testing
        // For now, this serves as a template

        vm.stopPrank();
    }

    // ============ Unit Tests (with mocks) ============

    function test_placeholder() public pure {
        // Placeholder test - will be replaced with real tests
        assertTrue(true);
    }
}

/**
 * @title CollateralSwapForkTest
 * @notice Fork tests for CollateralSwap contract on Sepolia
 */
contract CollateralSwapForkTest is Test {
    CollateralSwap public collateralSwap;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    // Use real Sepolia addresses
    address constant POOL_PROVIDER = 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A;
    address constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address constant USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address constant SWAP_ROUTER = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;

    // Note: Comet address needs to be found/deployed for Sepolia
    address constant COMET = address(0); // TBD

    function setUp() public {
        // This test requires SEPOLIA_RPC_URL to be set
        // string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        // vm.createSelectFork(rpcUrl);

        // Skip if no RPC URL or if Comet is not deployed
        if (COMET == address(0)) {
            return; // Skip setup if Comet address not set
        }

        vm.startPrank(owner);

        collateralSwap = new CollateralSwap(POOL_PROVIDER, COMET, SWAP_ROUTER, owner);

        // Add supported collaterals
        collateralSwap.addCollateral(WETH);
        collateralSwap.addCollateral(USDC);

        vm.stopPrank();
    }

    function test_fork_placeholder() public pure {
        // Placeholder - actual fork tests will be added once Comet address is confirmed
        assertTrue(true);
    }

    // ============ Fork Tests (to be implemented) ============

    // function test_fork_swapCollateral_WETH_to_USDC() public {
    //     // 1. Give user some WETH
    //     // 2. User supplies WETH to Comet as collateral
    //     // 3. User approves CollateralSwap contract on Comet
    //     // 4. User calls swapCollateral
    //     // 5. Verify user's collateral changed from WETH to USDC
    // }
}
