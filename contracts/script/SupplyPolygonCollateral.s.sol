// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {PolygonAddresses} from "../src/libraries/Addresses.sol";
import {IComet} from "../src/interfaces/compound/IComet.sol";

interface IWMATIC {
    function deposit() external payable;
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract SupplyPolygonCollateral is Script {
    address constant TEST_USER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function run() external {
        console2.log("=== Supplying WMATIC collateral to Polygon Comet for user ===");
        console2.log("User:", TEST_USER);
        console2.log("Chain ID:", block.chainid);

        require(block.chainid == PolygonAddresses.CHAIN_ID, "Not on Polygon fork");

        // Use Anvil default rich account #0 as supplier
        uint256 deployerPrivateKey =
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        console2.log("Deployer (supplier):", deployer);

        IComet comet = IComet(PolygonAddresses.COMET_USDC);
        IWMATIC wmatic = IWMATIC(PolygonAddresses.WMATIC);

        vm.startBroadcast(deployerPrivateKey);

        // Ensure deployer has enough MATIC and wrap into WMATIC
        vm.deal(deployer, 1_000 ether);
        uint256 wrapAmount = 400 ether;
        console2.log("Wrapping", wrapAmount / 1e18, "MATIC into WMATIC for deployer...");
        wmatic.deposit{value: wrapAmount}();

        uint256 wmaticBal = wmatic.balanceOf(deployer);
        console2.log("Deployer WMATIC balance:", wmaticBal);

        uint256 supplyAmount = (wmaticBal * 80) / 100; // supply 80% of deployer WMATIC
        console2.log("Supplying WMATIC amount on behalf of user:", supplyAmount);

        // Approve Comet to pull WMATIC and then supply as collateral for TEST_USER
        bool ok = wmatic.approve(address(comet), supplyAmount);
        require(ok, "WMATIC approve failed");

        comet.supplyTo(TEST_USER, PolygonAddresses.WMATIC, supplyAmount);

        vm.stopBroadcast();

        uint128 collBal = comet.collateralBalanceOf(TEST_USER, PolygonAddresses.WMATIC);
        console2.log("User WMATIC collateral in Comet after supply:", collBal);
    }
}


