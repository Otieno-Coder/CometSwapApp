// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FlashLoanReceiverBase} from "./FlashLoanReceiverBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FlashLoanTest
 * @notice Simple contract to test Aave V3 flash loans on Sepolia
 * @dev This contract demonstrates the basic flash loan flow:
 *      1. Request flash loan from Aave
 *      2. Receive funds in executeOperation callback
 *      3. Do something with the funds (in this case, nothing - just repay)
 *      4. Approve and repay the loan + premium
 *
 * This is Phase 1 verification - proving flash loans work on Sepolia.
 */
contract FlashLoanTest is FlashLoanReceiverBase {
    using SafeERC20 for IERC20;

    // ============ Events ============
    event FlashLoanExecuted(
        address indexed asset,
        uint256 amount,
        uint256 premium,
        address indexed initiator
    );

    event FlashLoanRequested(address indexed asset, uint256 amount);

    // ============ State ============
    /// @notice Track the last flash loan details for verification
    address public lastAsset;
    uint256 public lastAmount;
    uint256 public lastPremium;
    bool public lastSuccess;

    // ============ Constructor ============
    constructor(address poolAddressesProvider) FlashLoanReceiverBase(poolAddressesProvider) {}

    // ============ External Functions ============

    /**
     * @notice Execute a simple flash loan - borrow and immediately repay
     * @param asset The asset to flash borrow
     * @param amount The amount to borrow
     */
    function executeFlashLoan(address asset, uint256 amount) external {
        emit FlashLoanRequested(asset, amount);

        // Reset state
        lastAsset = address(0);
        lastAmount = 0;
        lastPremium = 0;
        lastSuccess = false;

        // Initiate flash loan
        // The callback will be executeOperation
        _initiateFlashLoan(asset, amount, "");
    }

    /**
     * @notice Callback from Aave Pool after flash loan is received
     * @dev This is where you would implement your arbitrage/liquidation/swap logic
     *      For this test, we just verify we received the funds and repay
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata /* params */
    ) external override returns (bool) {
        // Security: Only Aave Pool can call this
        require(msg.sender == address(POOL), "FlashLoanTest: caller must be Pool");
        require(initiator == address(this), "FlashLoanTest: initiator must be this contract");

        // Verify we received the funds
        uint256 balance = IERC20(asset).balanceOf(address(this));
        require(balance >= amount, "FlashLoanTest: did not receive flash loan");

        // ============================================================
        // This is where you would do something useful with the funds:
        // - Arbitrage between DEXes
        // - Liquidate undercollateralized positions
        // - Swap collateral (our use case!)
        // ============================================================

        // For this test, we just record the details and repay
        lastAsset = asset;
        lastAmount = amount;
        lastPremium = premium;

        // Approve the Pool to pull the repayment (amount + premium)
        _approveRepayment(asset, amount, premium);

        // Mark success
        lastSuccess = true;

        emit FlashLoanExecuted(asset, amount, premium, initiator);

        // Return true to indicate success
        // If we return false or revert, the entire transaction reverts
        return true;
    }

    // ============ View Functions ============

    /**
     * @notice Get the Aave Pool address (derived from PoolAddressesProvider)
     */
    function getPool() external view returns (address) {
        return address(POOL);
    }

    /**
     * @notice Get the flash loan premium (fee) in basis points
     * @return The premium (e.g., 5 = 0.05%)
     */
    function getFlashLoanPremium() external view returns (uint128) {
        return POOL.FLASHLOAN_PREMIUM_TOTAL();
    }

    /**
     * @notice Calculate the premium for a given flash loan amount
     * @param amount The flash loan amount
     * @return The premium amount
     */
    function calculatePremium(uint256 amount) external view returns (uint256) {
        uint128 premiumTotal = POOL.FLASHLOAN_PREMIUM_TOTAL();
        // Premium is in basis points (1 = 0.01%)
        // So premium = amount * premiumTotal / 10000
        return (amount * premiumTotal) / 10000;
    }

    /**
     * @notice Get details of the last flash loan
     */
    function getLastFlashLoanDetails()
        external
        view
        returns (address asset, uint256 amount, uint256 premium, bool success)
    {
        return (lastAsset, lastAmount, lastPremium, lastSuccess);
    }

    // ============ Emergency Functions ============

    /**
     * @notice Rescue any stuck tokens (in case something goes wrong)
     * @param token The token to rescue
     * @param to The recipient
     */
    function rescueTokens(address token, address to) external {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(to, balance);
        }
    }
}
