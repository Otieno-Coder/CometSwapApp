// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MainnetAddresses} from "../src/libraries/Addresses.sol";

/**
 * @title ISwapRouter02
 * @notice Minimal interface for Uniswap V3 SwapRouter02
 */
interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    // Multi-hop paths
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    // Unwrap WETH to ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;
}

/**
 * @title IQuoterV2
 * @notice Interface for getting swap quotes
 */
interface IQuoterV2 {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactOutputSingle(QuoteExactOutputSingleParams memory params)
        external
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}

/**
 * @title UniswapIntegrationTest
 * @notice Tests for Uniswap V3 swap integration on mainnet fork
 * @dev Run with: forge test --match-contract UniswapIntegrationTest --fork-url $MAINNET_RPC_URL -vvv
 */
contract UniswapIntegrationTest is Test {
    ISwapRouter02 public router;
    IQuoterV2 public quoter;

    IERC20 public weth;
    IERC20 public usdc;
    IERC20 public wbtc;

    address public testUser;

    // Whale addresses
    address constant WETH_WHALE = 0x8EB8a3b98659Cce290402893d0123abb75E3ab28;
    address constant USDC_WHALE = 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341;
    address constant WBTC_WHALE = 0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8;

    // Common fee tiers
    uint24 constant FEE_LOW = 500; // 0.05%
    uint24 constant FEE_MEDIUM = 3000; // 0.3%
    uint24 constant FEE_HIGH = 10000; // 1%

    function setUp() public {
        if (block.chainid != 1) {
            return;
        }

        router = ISwapRouter02(MainnetAddresses.UNISWAP_SWAP_ROUTER_02);
        quoter = IQuoterV2(MainnetAddresses.UNISWAP_QUOTER_V2);

        weth = IERC20(MainnetAddresses.WETH);
        usdc = IERC20(MainnetAddresses.USDC);
        wbtc = IERC20(MainnetAddresses.WBTC);

        testUser = makeAddr("testUser");

        console2.log("=== Uniswap Integration Test Setup ===");
        console2.log("SwapRouter02:", address(router));
        console2.log("QuoterV2:", address(quoter));
        console2.log("Chain ID:", block.chainid);
    }

    // ============ Quote Tests ============

    function test_fork_quoteWETHtoUSDC() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 amountIn = 1 ether; // 1 WETH

        console2.log("");
        console2.log("=== Quote WETH -> USDC ===");

        // Get quote
        (uint256 amountOut, uint160 sqrtPriceAfter, uint32 ticksCrossed, uint256 gasEstimate) =
            quoter.quoteExactInputSingle(
                IQuoterV2.QuoteExactInputSingleParams({
                    tokenIn: address(weth),
                    tokenOut: address(usdc),
                    amountIn: amountIn,
                    fee: FEE_MEDIUM, // 0.3% pool
                    sqrtPriceLimitX96: 0
                })
            );

        console2.log("Input: 1 WETH");
        console2.log("Output USDC:", amountOut);
        console2.log("Price (USDC per WETH):", amountOut / 1e6);
        console2.log("Ticks crossed:", ticksCrossed);
        console2.log("Gas estimate:", gasEstimate);

        assertTrue(amountOut > 0, "Should get USDC quote");
        // Sanity check: 1 ETH should be worth more than $100 USDC
        assertTrue(amountOut > 100e6, "WETH should be worth more than $100");
    }

    function test_fork_quoteUSDCtoWETH() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 amountIn = 3000e6; // 3000 USDC

        console2.log("");
        console2.log("=== Quote USDC -> WETH ===");

        (uint256 amountOut,,,) = quoter.quoteExactInputSingle(
            IQuoterV2.QuoteExactInputSingleParams({
                tokenIn: address(usdc),
                tokenOut: address(weth),
                amountIn: amountIn,
                fee: FEE_MEDIUM,
                sqrtPriceLimitX96: 0
            })
        );

        console2.log("Input: 3000 USDC");
        console2.log("Output WETH (wei):", amountOut);
        console2.log("Output WETH:", amountOut / 1e18);

        assertTrue(amountOut > 0, "Should get WETH quote");
    }

    function test_fork_quoteExactOutputWETHtoUSDC() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 amountOut = 3000e6; // Want exactly 3000 USDC

        console2.log("");
        console2.log("=== Quote Exact Output: ? WETH -> 3000 USDC ===");

        (uint256 amountIn,,,) = quoter.quoteExactOutputSingle(
            IQuoterV2.QuoteExactOutputSingleParams({
                tokenIn: address(weth),
                tokenOut: address(usdc),
                amount: amountOut,
                fee: FEE_MEDIUM,
                sqrtPriceLimitX96: 0
            })
        );

        console2.log("Output: 3000 USDC");
        console2.log("Input WETH needed (wei):", amountIn);

        assertTrue(amountIn > 0, "Should get WETH amount needed");
        // Should need roughly 1 ETH for $3000 (sanity check)
        assertTrue(amountIn < 2 ether, "Should need less than 2 ETH for $3000");
    }

    // ============ Swap Tests ============

    function test_fork_swapExactInputWETHtoUSDC() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 amountIn = 1 ether;

        console2.log("");
        console2.log("=== Swap Exact Input: 1 WETH -> USDC ===");

        // Get WETH from whale
        vm.prank(WETH_WHALE);
        weth.transfer(testUser, amountIn);

        // Get quote first
        (uint256 expectedOut,,,) = quoter.quoteExactInputSingle(
            IQuoterV2.QuoteExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: address(usdc),
                amountIn: amountIn,
                fee: FEE_MEDIUM,
                sqrtPriceLimitX96: 0
            })
        );

        console2.log("Expected USDC out:", expectedOut);

        // Execute swap
        vm.startPrank(testUser);
        weth.approve(address(router), amountIn);

        uint256 amountOut = router.exactInputSingle(
            ISwapRouter02.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: address(usdc),
                fee: FEE_MEDIUM,
                recipient: testUser,
                amountIn: amountIn,
                amountOutMinimum: expectedOut * 99 / 100, // 1% slippage
                sqrtPriceLimitX96: 0
            })
        );
        vm.stopPrank();

        // Verify
        uint256 usdcBalance = usdc.balanceOf(testUser);
        uint256 wethBalance = weth.balanceOf(testUser);

        console2.log("Actual USDC received:", amountOut);
        console2.log("User USDC balance:", usdcBalance);
        console2.log("User WETH balance:", wethBalance);

        assertEq(usdcBalance, amountOut, "USDC balance should match swap output");
        assertEq(wethBalance, 0, "All WETH should be spent");
        assertTrue(amountOut >= expectedOut * 99 / 100, "Should receive at least expected amount");
    }

    function test_fork_swapExactOutputUSDCtoWETH() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 amountOutDesired = 0.5 ether; // Want exactly 0.5 WETH
        uint256 usdcToStart = 5000e6; // Start with 5000 USDC (more than enough)

        console2.log("");
        console2.log("=== Swap Exact Output: USDC -> 0.5 WETH ===");

        // Get USDC from whale
        vm.prank(USDC_WHALE);
        usdc.transfer(testUser, usdcToStart);

        // Get quote to know max USDC needed
        (uint256 expectedIn,,,) = quoter.quoteExactOutputSingle(
            IQuoterV2.QuoteExactOutputSingleParams({
                tokenIn: address(usdc),
                tokenOut: address(weth),
                amount: amountOutDesired,
                fee: FEE_MEDIUM,
                sqrtPriceLimitX96: 0
            })
        );

        console2.log("Expected USDC needed:", expectedIn);

        // Execute swap
        vm.startPrank(testUser);
        usdc.approve(address(router), usdcToStart);

        uint256 amountIn = router.exactOutputSingle(
            ISwapRouter02.ExactOutputSingleParams({
                tokenIn: address(usdc),
                tokenOut: address(weth),
                fee: FEE_MEDIUM,
                recipient: testUser,
                amountOut: amountOutDesired,
                amountInMaximum: expectedIn * 101 / 100, // 1% slippage
                sqrtPriceLimitX96: 0
            })
        );
        vm.stopPrank();

        // Verify
        uint256 wethBalance = weth.balanceOf(testUser);
        uint256 usdcRemaining = usdc.balanceOf(testUser);
        uint256 usdcSpent = usdcToStart - usdcRemaining;

        console2.log("Actual USDC spent:", amountIn);
        console2.log("User WETH balance:", wethBalance);
        console2.log("User USDC remaining:", usdcRemaining);

        assertEq(wethBalance, amountOutDesired, "Should receive exact WETH amount");
        assertEq(usdcSpent, amountIn, "USDC spent should match");
        assertTrue(amountIn <= expectedIn * 101 / 100, "Should not exceed max slippage");
    }

    // ============ Multi-hop Swap Tests ============

    function test_fork_swapWBTCtoUSDCviaWETH() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 amountIn = 0.01e8; // 0.01 WBTC (8 decimals)

        console2.log("");
        console2.log("=== Multi-hop Swap: WBTC -> WETH -> USDC ===");

        // Get WBTC from whale
        vm.prank(WBTC_WHALE);
        wbtc.transfer(testUser, amountIn);

        console2.log("Input: 0.01 WBTC");

        // Encode path: WBTC -> WETH -> USDC
        // Path format: tokenIn, fee, tokenMid, fee, tokenOut
        bytes memory path = abi.encodePacked(
            address(wbtc),
            FEE_MEDIUM, // WBTC/WETH 0.3%
            address(weth),
            FEE_MEDIUM, // WETH/USDC 0.3%
            address(usdc)
        );

        // Execute multi-hop swap
        vm.startPrank(testUser);
        wbtc.approve(address(router), amountIn);

        uint256 amountOut = router.exactInput(
            ISwapRouter02.ExactInputParams({
                path: path,
                recipient: testUser,
                amountIn: amountIn,
                amountOutMinimum: 0 // For testing only, in production use proper slippage
            })
        );
        vm.stopPrank();

        // Verify
        uint256 usdcBalance = usdc.balanceOf(testUser);
        uint256 wbtcBalance = wbtc.balanceOf(testUser);

        console2.log("Output USDC:", amountOut);
        console2.log("User USDC balance:", usdcBalance);
        console2.log("User WBTC remaining:", wbtcBalance);

        assertEq(usdcBalance, amountOut, "USDC balance should match");
        assertEq(wbtcBalance, 0, "All WBTC should be spent");
        // 0.01 BTC at ~$88,000 should yield ~$880 USDC
        assertTrue(amountOut > 500e6, "Should receive more than $500 USDC for 0.01 BTC");
    }

    // ============ Slippage Test ============

    function test_fork_swapRevertsOnHighSlippage() public {
        if (block.chainid != 1) {
            vm.skip(true);
            return;
        }

        uint256 amountIn = 1 ether;

        console2.log("");
        console2.log("=== Slippage Protection Test ===");

        // Get WETH
        vm.prank(WETH_WHALE);
        weth.transfer(testUser, amountIn);

        // Get quote
        (uint256 expectedOut,,,) = quoter.quoteExactInputSingle(
            IQuoterV2.QuoteExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: address(usdc),
                amountIn: amountIn,
                fee: FEE_MEDIUM,
                sqrtPriceLimitX96: 0
            })
        );

        // Try swap with unrealistic minimum (expect revert)
        vm.startPrank(testUser);
        weth.approve(address(router), amountIn);

        // Set minimum to 110% of expected (impossible)
        uint256 impossibleMinimum = expectedOut * 110 / 100;

        vm.expectRevert();
        router.exactInputSingle(
            ISwapRouter02.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: address(usdc),
                fee: FEE_MEDIUM,
                recipient: testUser,
                amountIn: amountIn,
                amountOutMinimum: impossibleMinimum,
                sqrtPriceLimitX96: 0
            })
        );
        vm.stopPrank();

        console2.log("Correctly reverted when slippage protection triggered");
    }
}
