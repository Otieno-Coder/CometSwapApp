// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {MainnetAddresses} from "../src/libraries/Addresses.sol";

/// @notice Simple script to wrap some ETH into WETH for a test account on the local mainnet fork
///
/// Usage:
///   ETHERSCAN_API_KEY=dummy forge script script/SwapEthForWeth.s.sol \
///     --rpc-url http://127.0.0.1:8545 --broadcast -vv
contract SwapEthForWeth is Script {
    // Anvil default account #1 (used for frontend testing)
    address public constant USER1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function run() external {
        uint256 amount = 5 ether; // amount of ETH to wrap
        IWETH weth = IWETH(MainnetAddresses.WETH);

        console2.log("Wrapping ETH into WETH for user:", USER1);
        console2.log("Amount (ETH):", amount / 1e18);
        console2.log("WETH address:", address(weth));

        // Use default broadcaster (Anvil account #0) to wrap ETH,
        // then transfer WETH to USER1.
        vm.startBroadcast();
        weth.deposit{value: amount}();
        weth.transfer(USER1, amount);
        vm.stopBroadcast();

        uint256 balance = weth.balanceOf(USER1);
        console2.log("New WETH balance for user:", balance);
    }
}
