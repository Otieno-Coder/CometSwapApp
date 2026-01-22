// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IPoolAddressesProvider} from "../src/interfaces/aave/IPoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title AavePoolInfoTest
 * @notice Diagnostic test to check Aave V3 pool state on Sepolia
 */
contract AavePoolInfoTest is Test {
    // Known Sepolia token addresses
    address constant POOL_PROVIDER = 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A;
    
    // Tokens to check
    address constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address constant USDC_COMET = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // From Comet config
    
    // Aave's own testnet tokens (different from Comet's)
    address constant USDC_AAVE = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address constant DAI_AAVE = 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;
    address constant LINK_AAVE = 0xf8Fb3713D459D7C1018BD0A49D19b4C44290EBE5;
    address constant USDT_AAVE = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;
    address constant WBTC_AAVE = 0x29f2D40B0605204364af54EC677bD022dA425d03;

    function test_fork_checkAavePoolState() public {
        if (block.chainid != 11155111) {
            vm.skip(true);
            return;
        }

        address poolAddress = IPoolAddressesProvider(POOL_PROVIDER).getPool();
        
        console2.log("=== Aave V3 Pool Info on Sepolia ===");
        console2.log("Pool Address:", poolAddress);
        console2.log("");

        console2.log("=== Token Balances in Pool ===");
        
        // Check each token
        _checkBalance("WETH (Uniswap)", WETH, poolAddress);
        _checkBalance("USDC (Comet)", USDC_COMET, poolAddress);
        _checkBalance("USDC (Aave)", USDC_AAVE, poolAddress);
        _checkBalance("DAI (Aave)", DAI_AAVE, poolAddress);
        _checkBalance("LINK (Aave)", LINK_AAVE, poolAddress);
        _checkBalance("USDT (Aave)", USDT_AAVE, poolAddress);
        _checkBalance("WBTC (Aave)", WBTC_AAVE, poolAddress);
        
        console2.log("");
        console2.log("=== Notes ===");
        console2.log("- Aave testnet uses its own token addresses");
        console2.log("- Flash loans may be disabled for some assets");
        console2.log("- Use Aave testnet tokens for flash loan testing");
    }

    function _checkBalance(string memory name, address token, address pool) internal view {
        try IERC20(token).balanceOf(pool) returns (uint256 balance) {
            console2.log(name, ":", balance);
        } catch {
            console2.log(name, ": FAILED to read balance");
        }
    }
}
