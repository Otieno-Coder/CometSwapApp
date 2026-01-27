// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {MainnetAddresses} from "../src/libraries/Addresses.sol";
import {IComet} from "../src/interfaces/compound/IComet.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract SetupMainnetTestAccount is Script {
    // Use the second anvil default account as the user (matches your earlier runs)
    address constant TEST_USER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function run() external {
        console2.log("=== Setting up Ethereum mainnet fork test account ===");
        console2.log("User:", TEST_USER);
        console2.log("Chain ID:", block.chainid);

        require(block.chainid == MainnetAddresses.CHAIN_ID, "Not on mainnet fork");

        // Anvil default rich account #0
        uint256 deployerPrivateKey =
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        console2.log("Deployer:", deployer);

        IComet comet = IComet(MainnetAddresses.COMET_USDC);
        IERC20 weth = IERC20(MainnetAddresses.WETH);

        vm.startBroadcast(deployerPrivateKey);

        // Give the user ETH for gas
        vm.deal(TEST_USER, 1_000 ether);

        // Fund deployer with lots of WETH by overriding its balance slot, then transfer to user
        uint256 wethAmount = 100 ether;
        bytes32 slot0 = bytes32(uint256(3)); // WETH9 balanceOf mapping slot; 3 is correct for canonical WETH9
        bytes32 userSlot = keccak256(abi.encode(TEST_USER, slot0));
        vm.store(MainnetAddresses.WETH, userSlot, bytes32(wethAmount));

        console2.log("WETH sent to user (via store):", wethAmount);

        // Approve and supply WETH as collateral into Comet for the user
        // We call supplyTo from the deployer on behalf of TEST_USER
        uint256 userWethBal = weth.balanceOf(TEST_USER);
        console2.log("User WETH balance before supply:", userWethBal);

        uint256 supplyAmount = (userWethBal * 80) / 100; // supply 80% of WETH
        console2.log("Supplying WETH amount on behalf of user:", supplyAmount);

        // Give deployer the same amount so it can supplyTo
        bytes32 deployerSlot = keccak256(abi.encode(deployer, slot0));
        vm.store(MainnetAddresses.WETH, deployerSlot, bytes32(supplyAmount));

        bool ok = weth.approve(address(comet), supplyAmount);
        require(ok, "WETH approve failed");

        comet.supplyTo(TEST_USER, MainnetAddresses.WETH, supplyAmount);

        vm.stopBroadcast();

        uint128 collBal = comet.collateralBalanceOf(TEST_USER, MainnetAddresses.WETH);
        console2.log("User WETH collateral in Comet:", collBal);
    }
}

