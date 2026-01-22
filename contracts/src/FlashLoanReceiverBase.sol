// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IFlashLoanSimpleReceiver, IPoolAddressesProvider, IPool} from "./interfaces/aave/IFlashLoanReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FlashLoanReceiverBase
 * @notice Base contract for receiving Aave V3 flash loans
 * @dev Inherit from this contract to create flash loan receiving contracts
 */
abstract contract FlashLoanReceiverBase is IFlashLoanSimpleReceiver {
    using SafeERC20 for IERC20;

    // ============ Immutables ============
    IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    IPool public immutable override POOL;

    // ============ Constructor ============
    constructor(address poolAddressesProvider) {
        ADDRESSES_PROVIDER = IPoolAddressesProvider(poolAddressesProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
    }

    // ============ Flash Loan Functions ============

    /**
     * @notice Initiates a simple flash loan
     * @param asset The address of the asset to flash borrow
     * @param amount The amount to flash borrow
     * @param params Encoded parameters to pass to executeOperation
     */
    function _initiateFlashLoan(address asset, uint256 amount, bytes memory params) internal {
        POOL.flashLoanSimple(
            address(this), // receiver
            asset,
            amount,
            params,
            0 // referral code
        );
    }

    /**
     * @notice Callback function for Aave flash loans
     * @dev Override this in child contracts to implement custom logic
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external virtual override returns (bool);

    // ============ Internal Helpers ============

    /**
     * @notice Approves the Pool to pull the repayment amount
     * @param asset The asset to approve
     * @param amount The amount borrowed
     * @param premium The flash loan fee
     */
    function _approveRepayment(address asset, uint256 amount, uint256 premium) internal {
        uint256 amountOwed = amount + premium;
        IERC20(asset).forceApprove(address(POOL), amountOwed);
    }
}
