// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {PolygonAddresses} from "../src/libraries/Addresses.sol";

interface IWMATIC {
    function deposit() external payable;
    function balanceOf(address) external view returns (uint256);
}

contract SetupPolygonTestAccount is Script {
    address constant TEST_USER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function run() external {
        console2.log("=== Setting up Polygon test account ===");
        console2.log("User:", TEST_USER);
        console2.log("Chain ID:", block.chainid);

        require(block.chainid == PolygonAddresses.CHAIN_ID, "Not on Polygon fork");

        // Use Anvil default rich account #0
        uint256 deployerPrivateKey =
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        console2.log("Deployer:", deployer);

        // Use deployer to wrap MATIC and then transfer WMATIC to the user
        IWMATIC wmatic = IWMATIC(PolygonAddresses.WMATIC);
        uint256 wrapAmount = 500 ether;

        vm.startBroadcast(deployerPrivateKey);

        // Ensure deployer has enough MATIC to wrap
        vm.deal(deployer, 1_000 ether);
        console2.log("Deployer MATIC before wrap:", deployer.balance / 1e18);

        console2.log("Wrapping", wrapAmount / 1e18, "MATIC into WMATIC for deployer...");
        wmatic.deposit{value: wrapAmount}();

        console2.log("Transferring WMATIC to user...");
        (bool ok,) = address(wmatic).call(
            abi.encodeWithSignature("transfer(address,uint256)", TEST_USER, wrapAmount)
        );
        require(ok, "WMATIC transfer failed");

        // Also give the user native MATIC for gas
        vm.deal(TEST_USER, 1_000 ether);
        vm.stopBroadcast();

        console2.log("=== Final balances on Polygon fork ===");
        console2.log("User MATIC:", TEST_USER.balance / 1e18);
        console2.log("User WMATIC:", wmatic.balanceOf(TEST_USER));
    }
}

