// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {MainnetAddresses} from "../src/libraries/Addresses.sol";
import {IComet} from "../src/interfaces/compound/IComet.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @notice Script to fund the usual test user with WETH and supply it as collateral
///         into the mainnet USDC Comet on the local mainnet fork.
contract SetupMainnetForkCollateral is Script, StdCheats {
    // Anvil default account #1 (your usual test address)
    address constant TEST_USER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function run() external {
        console2.log("=== Setting up WETH collateral for mainnet fork user ===");
        console2.log("User:", TEST_USER);
        console2.log("Chain ID:", block.chainid);

        require(block.chainid == MainnetAddresses.CHAIN_ID, "Not on mainnet fork");

        // Use rich Anvil default account #0 for transactions
        uint256 deployerPrivateKey =
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        console2.log("Deployer:", deployer);

        IComet comet = IComet(MainnetAddresses.COMET_USDC);
        IERC20 weth = IERC20(MainnetAddresses.WETH);

        // 1) Give the test user some ETH for gas (in case you use it later)
        vm.deal(TEST_USER, 1_000 ether);
        console2.log("User ETH after deal:", TEST_USER.balance / 1e18, "ETH");

        // 2) Give the deployer a large WETH balance via ERC20 deal cheat
        uint256 wethAmount = 100 ether;
        deal(MainnetAddresses.WETH, deployer, wethAmount, true);
        console2.log("Deployer WETH after deal:", weth.balanceOf(deployer));

        vm.startBroadcast(deployerPrivateKey);

        // 3) Approve Comet and supply WETH as collateral on behalf of TEST_USER
        uint256 supplyAmount = (wethAmount * 80) / 100; // supply 80% of WETH to user
        console2.log("Supplying WETH amount on behalf of user:", supplyAmount);

        bool ok = weth.approve(address(comet), supplyAmount);
        require(ok, "WETH approve failed");

        comet.supplyTo(TEST_USER, MainnetAddresses.WETH, supplyAmount);

        vm.stopBroadcast();

        uint128 collBal = comet.collateralBalanceOf(TEST_USER, MainnetAddresses.WETH);
        console2.log("User WETH collateral in Comet:", collBal);
    }
}

