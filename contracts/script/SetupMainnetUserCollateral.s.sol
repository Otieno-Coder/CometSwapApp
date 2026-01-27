// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {MainnetAddresses} from "../src/libraries/Addresses.sol";
import {IComet} from "../src/interfaces/compound/IComet.sol";

interface IWETH {
    function deposit() external payable;
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @notice One-shot script to fund *your* account on the mainnet fork with ETH,
/// wrap some to WETH, and supply WETH as collateral into the USDC Comet.
/// @dev Uses TEST_USER_PRIVATE_KEY from env so you control the account.
contract SetupMainnetUserCollateral is Script {
    function run() external {
        // Read your private key from env (you set this before running the script)
        uint256 userPrivateKey = vm.envUint("TEST_USER_PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);

        console2.log("=== Setting up user on Ethereum mainnet fork ===");
        console2.log("User:", user);
        console2.log("Chain ID:", block.chainid);

        require(block.chainid == MainnetAddresses.CHAIN_ID, "Not on mainnet fork");

        IComet comet = IComet(MainnetAddresses.COMET_USDC);
        IWETH weth = IWETH(MainnetAddresses.WETH);

        // 1) Give user plenty of ETH on the fork (for gas + wrapping)
        vm.deal(user, 1_000 ether);
        console2.log("User ETH after deal:", user.balance / 1e18, "ETH");

        // 2) As the user, wrap some ETH into WETH and supply to Comet
        vm.startBroadcast(userPrivateKey);

        uint256 wrapAmount = 100 ether;
        console2.log("Wrapping", wrapAmount / 1e18, "ETH into WETH...");
        weth.deposit{value: wrapAmount}();

        uint256 wethBal = weth.balanceOf(user);
        console2.log("User WETH balance after wrap:", wethBal);

        uint256 supplyAmount = (wethBal * 80) / 100; // supply 80% as collateral
        console2.log("Supplying WETH amount to Comet:", supplyAmount);

        bool ok = weth.approve(address(comet), supplyAmount);
        require(ok, "WETH approve failed");

        comet.supply(MainnetAddresses.WETH, supplyAmount);

        vm.stopBroadcast();

        uint128 collBal = comet.collateralBalanceOf(user, MainnetAddresses.WETH);
        console2.log("User WETH collateral in Comet:", collBal);
    }
}

