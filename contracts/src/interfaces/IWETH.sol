// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWETH
 * @notice Interface for Wrapped Ether
 */
interface IWETH is IERC20 {
    /**
     * @notice Deposit ETH and receive WETH
     */
    function deposit() external payable;

    /**
     * @notice Withdraw ETH by burning WETH
     * @param amount The amount of WETH to withdraw
     */
    function withdraw(uint256 amount) external;
}
