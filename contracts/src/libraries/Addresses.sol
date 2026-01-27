// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SepoliaAddresses
 * @notice Library containing verified contract addresses for Sepolia testnet
 * @dev Source: https://github.com/compound-finance/comet/tree/main/deployments/sepolia
 */
library SepoliaAddresses {
    // ============ Network Info ============
    uint256 constant CHAIN_ID = 11155111;

    // ============ Compound V3 (Comet) - USDC Market ============
    // Source: https://github.com/compound-finance/comet/blob/main/deployments/sepolia/usdc/roots.json
    address constant COMET_USDC = 0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e;
    address constant COMET_CONFIGURATOR = 0xc28aD44975C614EaBe0Ed090207314549e1c6624;
    address constant COMET_REWARDS = 0x8bF5b658bdF0388E8b482ED51B14aef58f90abfD;
    address constant COMET_BULKER = 0x157c001bb1F8b33743B14483Be111C961d8e11dE;
    address constant COMET_FAUCETEER = 0x68793eA49297eB75DFB4610B68e076D2A5c7646C;

    // ============ Compound V3 (Comet) - WETH Market ============
    // Source: https://github.com/compound-finance/comet/blob/main/deployments/sepolia/weth/roots.json
    address constant COMET_WETH = 0x2943ac1216979aD8dB76D9147F64E61adc126e96;
    address constant COMET_BULKER_WETH = 0xaD0C044425D81a2E223f4CE699156900fead2Aaa;

    // ============ Uniswap V3 ============
    // Source: https://docs.uniswap.org/contracts/v3/reference/deployments/ethereum-deployments
    address constant UNISWAP_V3_FACTORY = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
    address constant UNISWAP_SWAP_ROUTER_02 = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;
    address constant UNISWAP_QUOTER_V2 = 0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3;
    address constant UNISWAP_UNIVERSAL_ROUTER = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;

    // ============ Aave V3 ============
    address constant AAVE_POOL_ADDRESSES_PROVIDER = 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A;
    // Pool address derived from PoolAddressesProvider.getPool() - verified on Sepolia
    address constant AAVE_POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;

    // ============ Tokens (Comet) ============
    // These are the tokens used by Comet on Sepolia
    // USDC - Circle's test USDC on Sepolia (from Comet config)
    address constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    // WETH - Uniswap's WETH9 on Sepolia
    address constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    // ============ Tokens (Aave) ============
    // IMPORTANT: Aave uses different testnet tokens than Comet!
    // These are required for flash loans on Aave Sepolia
    address constant USDC_AAVE = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address constant DAI_AAVE = 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;
    address constant USDT_AAVE = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;
    address constant WBTC_AAVE = 0x29f2D40B0605204364af54EC677bD022dA425d03;
    address constant LINK_AAVE = 0xf8Fb3713D459D7C1018BD0A49D19b4C44290EBE5;

    // ============ Chainlink Price Feeds (from Comet config) ============
    address constant USDC_USD_FEED = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
    address constant ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address constant BTC_USD_FEED = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;
    address constant COMP_USD_FEED = 0x619db7F74C0061E2917D1D57f834D9D24C5529dA;

    // ============ Fee Tiers (Uniswap V3) ============
    uint24 constant FEE_LOWEST = 100; // 0.01%
    uint24 constant FEE_LOW = 500; // 0.05%
    uint24 constant FEE_MEDIUM = 3000; // 0.3%
    uint24 constant FEE_HIGH = 10000; // 1%
}

/**
 * @title MainnetAddresses
 * @notice Library containing contract addresses for Ethereum mainnet (for reference/fork testing)
 */
library MainnetAddresses {
    // ============ Network Info ============
    uint256 constant CHAIN_ID = 1;

    // ============ Compound V3 (Comet) ============
    address constant COMET_USDC = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
    address constant COMET_WETH = 0xA17581A9E3356d9A858b789D68B4d866e593aE94;

    // ============ Uniswap V3 ============
    address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant UNISWAP_SWAP_ROUTER_02 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant UNISWAP_QUOTER_V2 = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;

    // ============ Aave V3 ============
    address constant AAVE_POOL_ADDRESSES_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;

    // ============ Tokens ============
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    // ============ Fee Tiers (Uniswap V3) ============
    uint24 constant FEE_LOWEST = 100;
    uint24 constant FEE_LOW = 500;
    uint24 constant FEE_MEDIUM = 3000;
    uint24 constant FEE_HIGH = 10000;
}

/**
 * @title PolygonAddresses
 * @notice Library containing contract addresses for Polygon (for reference/fork testing)
 * @dev Comet addresses from deployments/polygon/usdc in the official comet repo:
 *      https://github.com/compound-finance/comet
 */
library PolygonAddresses {
    // ============ Network Info ============
    uint256 constant CHAIN_ID = 137;

    // ============ Compound V3 (Comet) - USDC Market ============
    // Source: deployments/polygon/usdc/roots.json
    address constant COMET_USDC = 0xF25212E676D1F7F89Cd72fFEe66158f541246445;

    // ============ Tokens (from deployments/polygon/usdc/configuration.json) ============
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address constant WBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    // ============ Uniswap V3 ============
    // Note: Uniswap v3 periphery is deployed at shared addresses on multiple chains.
    // Router/Quoter here follow the common cross-chain addresses used by Uniswap.
    address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant UNISWAP_SWAP_ROUTER_02 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant UNISWAP_QUOTER_V2 = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;

    // ============ Aave V3 ============
    // Source: Aave v3 Polygon docs (PoolAddressesProvider)
    address constant AAVE_POOL_ADDRESSES_PROVIDER = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;

    // ============ Fee Tiers (Uniswap V3) ============
    uint24 constant FEE_LOWEST = 100;
    uint24 constant FEE_LOW = 500;
    uint24 constant FEE_MEDIUM = 3000;
    uint24 constant FEE_HIGH = 10000;
}
