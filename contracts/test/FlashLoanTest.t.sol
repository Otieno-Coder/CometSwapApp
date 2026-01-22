// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {FlashLoanTest} from "../src/FlashLoanTest.sol";
import {SepoliaAddresses} from "../src/libraries/Addresses.sol";
import {IPoolAddressesProvider} from "../src/interfaces/aave/IPoolAddressesProvider.sol";
import {IPool} from "../src/interfaces/aave/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FlashLoanTestUnit
 * @notice Unit tests for FlashLoanTest contract (mock-based)
 */
contract FlashLoanTestUnit is Test {
    // Placeholder for unit tests with mocks
    function test_placeholder() public pure {
        assertTrue(true);
    }
}

/**
 * @title FlashLoanTestFork
 * @notice Fork tests for FlashLoanTest on Sepolia
 * @dev Run with: forge test --match-contract FlashLoanTestFork --fork-url $SEPOLIA_RPC_URL -vvv
 */
contract FlashLoanTestFork is Test {
    FlashLoanTest public flashLoanTest;

    // Sepolia addresses
    address constant POOL_PROVIDER = 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A;
    address constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    
    // Comet uses Circle's USDC
    address constant USDC_COMET = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    
    // Aave uses its own testnet tokens (different addresses!)
    address constant USDC_AAVE = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address constant DAI_AAVE = 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;

    address public poolAddress;
    address public testUser;

    function setUp() public {
        // Check if we're on a fork
        if (block.chainid != 11155111) {
            // Skip setup if not on Sepolia fork
            return;
        }

        testUser = makeAddr("testUser");

        // Deploy FlashLoanTest
        flashLoanTest = new FlashLoanTest(POOL_PROVIDER);

        // Get the actual Pool address
        poolAddress = IPoolAddressesProvider(POOL_PROVIDER).getPool();

        console2.log("=== Test Setup ===");
        console2.log("FlashLoanTest deployed at:", address(flashLoanTest));
        console2.log("Pool Address:", poolAddress);
        console2.log("Chain ID:", block.chainid);
    }

    // ============ Verification Tests ============

    function test_fork_verifyPoolAddress() public {
        if (block.chainid != 11155111) {
            vm.skip(true);
            return;
        }

        // Verify we can get the Pool address
        address pool = flashLoanTest.getPool();
        console2.log("Pool from FlashLoanTest:", pool);

        assertTrue(pool != address(0), "Pool address should not be zero");
        assertEq(pool, poolAddress, "Pool addresses should match");
    }

    function test_fork_verifyFlashLoanPremium() public {
        if (block.chainid != 11155111) {
            vm.skip(true);
            return;
        }

        uint128 premium = flashLoanTest.getFlashLoanPremium();
        console2.log("Flash Loan Premium:", premium, "basis points");

        // Aave V3 typically has 5 basis points (0.05%) premium
        // But it can vary, so just check it's reasonable (0-100 bps)
        assertTrue(premium <= 100, "Premium should be <= 100 basis points");
    }

    function test_fork_calculatePremium() public {
        if (block.chainid != 11155111) {
            vm.skip(true);
            return;
        }

        uint256 amount = 1000e6; // 1000 USDC
        uint256 premium = flashLoanTest.calculatePremium(amount);

        console2.log("Flash loan amount:", amount);
        console2.log("Calculated premium:", premium);

        // With 5 bps (0.05%), premium for 1000 USDC = 0.5 USDC = 500000
        // But let's just verify it's > 0 and reasonable
        assertTrue(premium > 0, "Premium should be > 0");
        assertTrue(premium < amount, "Premium should be < amount");
    }

    // ============ Flash Loan Execution Tests ============

    /**
     * @notice Test executing a flash loan with WETH
     * @dev This requires the Aave Pool to have WETH liquidity
     */
    function test_fork_executeFlashLoan_WETH() public {
        if (block.chainid != 11155111) {
            vm.skip(true);
            return;
        }

        uint256 amount = 0.01 ether; // Small amount for testing

        // Check if Pool has enough WETH
        uint256 poolBalance = IERC20(WETH).balanceOf(poolAddress);
        console2.log("Pool WETH balance:", poolBalance);

        if (poolBalance < amount) {
            console2.log("Skipping: Pool has insufficient WETH liquidity");
            vm.skip(true);
            return;
        }

        // Calculate premium needed
        uint256 premiumAmount = flashLoanTest.calculatePremium(amount);
        uint256 totalNeeded = amount + premiumAmount;

        console2.log("Amount to borrow:", amount);
        console2.log("Premium needed:", premiumAmount);
        console2.log("Total needed for repayment:", totalNeeded);

        // Fund the contract with enough WETH to pay the premium
        // In a real scenario, you'd generate this profit during the flash loan
        deal(WETH, address(flashLoanTest), premiumAmount);

        // Verify contract has the premium
        uint256 contractBalance = IERC20(WETH).balanceOf(address(flashLoanTest));
        console2.log("Contract WETH balance before:", contractBalance);
        assertTrue(contractBalance >= premiumAmount, "Contract needs premium amount");

        // Execute flash loan
        flashLoanTest.executeFlashLoan(WETH, amount);

        // Verify success
        (address lastAsset, uint256 lastAmount, uint256 lastPremium, bool success) =
            flashLoanTest.getLastFlashLoanDetails();

        console2.log("=== Flash Loan Result ===");
        console2.log("Success:", success);
        console2.log("Asset:", lastAsset);
        console2.log("Amount:", lastAmount);
        console2.log("Premium paid:", lastPremium);

        assertTrue(success, "Flash loan should succeed");
        assertEq(lastAsset, WETH, "Asset should be WETH");
        assertEq(lastAmount, amount, "Amount should match");
    }

    /**
     * @notice Test executing a flash loan with Aave's USDC
     * @dev Aave uses its own testnet tokens, not Comet's USDC
     */
    function test_fork_executeFlashLoan_USDC_Aave() public {
        if (block.chainid != 11155111) {
            vm.skip(true);
            return;
        }

        uint256 amount = 100e6; // 100 USDC

        // Check if Pool has enough USDC (using Aave's USDC token)
        uint256 poolBalance = IERC20(USDC_AAVE).balanceOf(poolAddress);
        console2.log("Pool USDC (Aave) balance:", poolBalance);

        if (poolBalance < amount) {
            console2.log("Skipping: Pool has insufficient USDC liquidity");
            vm.skip(true);
            return;
        }

        // Calculate premium needed
        uint256 premiumAmount = flashLoanTest.calculatePremium(amount);

        console2.log("Amount to borrow:", amount);
        console2.log("Premium needed:", premiumAmount);

        // Fund the contract with premium (need more than exact premium due to rounding)
        deal(USDC_AAVE, address(flashLoanTest), premiumAmount + 1000);

        uint256 contractBalance = IERC20(USDC_AAVE).balanceOf(address(flashLoanTest));
        console2.log("Contract USDC balance:", contractBalance);

        // Execute flash loan
        flashLoanTest.executeFlashLoan(USDC_AAVE, amount);

        // Verify success
        (address lastAsset, uint256 lastAmount, uint256 lastPremium, bool success) =
            flashLoanTest.getLastFlashLoanDetails();

        console2.log("=== Flash Loan Result ===");
        console2.log("Success:", success);
        console2.log("Asset:", lastAsset);
        console2.log("Amount:", lastAmount);
        console2.log("Premium paid:", lastPremium);

        assertTrue(success, "Flash loan should succeed");
        assertEq(lastAsset, USDC_AAVE, "Asset should be Aave USDC");
        assertEq(lastAmount, amount, "Amount should match");
    }

    /**
     * @notice Test executing a flash loan with DAI
     * @dev DAI has good liquidity on Aave Sepolia
     */
    function test_fork_executeFlashLoan_DAI() public {
        if (block.chainid != 11155111) {
            vm.skip(true);
            return;
        }

        uint256 amount = 100e18; // 100 DAI

        // Check if Pool has enough DAI
        uint256 poolBalance = IERC20(DAI_AAVE).balanceOf(poolAddress);
        console2.log("Pool DAI balance:", poolBalance);

        if (poolBalance < amount) {
            console2.log("Skipping: Pool has insufficient DAI liquidity");
            vm.skip(true);
            return;
        }

        // Calculate premium needed
        uint256 premiumAmount = flashLoanTest.calculatePremium(amount);

        console2.log("Amount to borrow:", amount);
        console2.log("Premium needed:", premiumAmount);

        // Fund the contract with premium
        deal(DAI_AAVE, address(flashLoanTest), premiumAmount + 1e18);

        uint256 contractBalance = IERC20(DAI_AAVE).balanceOf(address(flashLoanTest));
        console2.log("Contract DAI balance:", contractBalance);

        // Execute flash loan
        flashLoanTest.executeFlashLoan(DAI_AAVE, amount);

        // Verify success
        (address lastAsset, uint256 lastAmount, uint256 lastPremium, bool success) =
            flashLoanTest.getLastFlashLoanDetails();

        console2.log("=== Flash Loan Result ===");
        console2.log("Success:", success);
        console2.log("Asset:", lastAsset);
        console2.log("Amount:", lastAmount);
        console2.log("Premium paid:", lastPremium);

        assertTrue(success, "Flash loan should succeed");
    }

    // ============ Failure Tests ============

    function test_fork_flashLoan_failsWithInsufficientPremium() public {
        if (block.chainid != 11155111) {
            vm.skip(true);
            return;
        }

        uint256 amount = 0.01 ether;

        // Check pool has liquidity
        uint256 poolBalance = IERC20(WETH).balanceOf(poolAddress);
        if (poolBalance < amount) {
            vm.skip(true);
            return;
        }

        // Don't fund the contract - it won't have enough to pay premium
        // The flash loan should revert

        vm.expectRevert();
        flashLoanTest.executeFlashLoan(WETH, amount);
    }
}

/**
 * @title FlashLoanIntegrationTest
 * @notice Integration tests that run on real Sepolia (requires deployment)
 */
contract FlashLoanIntegrationTest is Test {
    // These tests would be run against an already-deployed contract
    // For now, placeholder

    function test_integration_placeholder() public pure {
        assertTrue(true);
    }
}
