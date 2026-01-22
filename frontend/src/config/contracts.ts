import { Address } from 'viem';

// ============ Network Configuration ============
export const SUPPORTED_CHAIN_ID = 1; // Mainnet (use fork for testing)

// ============ Contract Addresses (Mainnet) ============
export const addresses = {
  // Compound V3 (Comet)
  COMET_USDC: '0xc3d688B66703497DAA19211EEdff47f25384cdc3' as Address,
  COMET_WETH: '0xA17581A9E3356d9A858b789D68B4d866e593aE94' as Address,

  // Tokens
  USDC: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48' as Address,
  WETH: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2' as Address,
  WBTC: '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599' as Address,
  COMP: '0xc00e94Cb662C3520282E6f5717214004A7f26888' as Address,
  UNI: '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984' as Address,
  LINK: '0x514910771AF9Ca656af840dff83E8264EcF986CA' as Address,

  // Uniswap
  UNISWAP_ROUTER: '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45' as Address,
  UNISWAP_QUOTER: '0x61fFE014bA17989E743c5F6cB21bF9697530B21e' as Address,

  // Aave
  AAVE_POOL: '0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2' as Address,

  // CollateralSwap (to be deployed)
  COLLATERAL_SWAP: '0x8b941d833A740bcFd9Cee5B873FFbB8EbAdA6EF0' as Address,
} as const;

// ============ Token Metadata ============
export interface TokenInfo {
  address: Address;
  symbol: string;
  name: string;
  decimals: number;
  logoUrl?: string;
}

export const tokens: Record<string, TokenInfo> = {
  USDC: {
    address: addresses.USDC,
    symbol: 'USDC',
    name: 'USD Coin',
    decimals: 6,
    logoUrl: 'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48/logo.png',
  },
  WETH: {
    address: addresses.WETH,
    symbol: 'WETH',
    name: 'Wrapped Ether',
    decimals: 18,
    logoUrl: 'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2/logo.png',
  },
  WBTC: {
    address: addresses.WBTC,
    symbol: 'WBTC',
    name: 'Wrapped Bitcoin',
    decimals: 8,
    logoUrl: 'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599/logo.png',
  },
  COMP: {
    address: addresses.COMP,
    symbol: 'COMP',
    name: 'Compound',
    decimals: 18,
    logoUrl: 'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xc00e94Cb662C3520282E6f5717214004A7f26888/logo.png',
  },
  UNI: {
    address: addresses.UNI,
    symbol: 'UNI',
    name: 'Uniswap',
    decimals: 18,
    logoUrl: 'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984/logo.png',
  },
  LINK: {
    address: addresses.LINK,
    symbol: 'LINK',
    name: 'Chainlink',
    decimals: 18,
    logoUrl: 'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0x514910771AF9Ca656af840dff83E8264EcF986CA/logo.png',
  },
};

// ============ Comet Collateral Assets ============
export const cometCollaterals = [
  tokens.WETH,
  tokens.WBTC,
  tokens.COMP,
  tokens.UNI,
  tokens.LINK,
];

// Helper to get token by address
export function getTokenByAddress(address: Address): TokenInfo | undefined {
  return Object.values(tokens).find(
    (t) => t.address.toLowerCase() === address.toLowerCase()
  );
}

// ============ ABIs ============

// Minimal Comet ABI for reading positions
export const cometAbi = [
  {
    inputs: [{ name: 'account', type: 'address' }, { name: 'asset', type: 'address' }],
    name: 'collateralBalanceOf',
    outputs: [{ name: '', type: 'uint128' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'account', type: 'address' }],
    name: 'borrowBalanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'account', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'account', type: 'address' }],
    name: 'isLiquidatable',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'account', type: 'address' }],
    name: 'isBorrowCollateralized',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'numAssets',
    outputs: [{ name: '', type: 'uint8' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'i', type: 'uint8' }],
    name: 'getAssetInfo',
    outputs: [
      {
        components: [
          { name: 'offset', type: 'uint8' },
          { name: 'asset', type: 'address' },
          { name: 'priceFeed', type: 'address' },
          { name: 'scale', type: 'uint64' },
          { name: 'borrowCollateralFactor', type: 'uint64' },
          { name: 'liquidateCollateralFactor', type: 'uint64' },
          { name: 'liquidationFactor', type: 'uint64' },
          { name: 'supplyCap', type: 'uint128' },
        ],
        name: '',
        type: 'tuple',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'priceFeed', type: 'address' }],
    name: 'getPrice',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'baseToken',
    outputs: [{ name: '', type: 'address' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'baseTokenPriceFeed',
    outputs: [{ name: '', type: 'address' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'getUtilization',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'utilization', type: 'uint256' }],
    name: 'getSupplyRate',
    outputs: [{ name: '', type: 'uint64' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'utilization', type: 'uint256' }],
    name: 'getBorrowRate',
    outputs: [{ name: '', type: 'uint64' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'manager', type: 'address' }, { name: 'isAllowed', type: 'bool' }],
    name: 'allow',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'owner', type: 'address' }, { name: 'manager', type: 'address' }],
    name: 'isAllowed',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const;

// ERC20 ABI
export const erc20Abi = [
  {
    inputs: [{ name: 'account', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'owner', type: 'address' }, { name: 'spender', type: 'address' }],
    name: 'allowance',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'spender', type: 'address' }, { name: 'amount', type: 'uint256' }],
    name: 'approve',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [],
    name: 'decimals',
    outputs: [{ name: '', type: 'uint8' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'symbol',
    outputs: [{ name: '', type: 'string' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const;

// CollateralSwap ABI
export const collateralSwapAbi = [
  {
    inputs: [
      { name: 'sourceAsset', type: 'address' },
      { name: 'targetAsset', type: 'address' },
      { name: 'sourceAmount', type: 'uint256' },
      { name: 'minTargetAmount', type: 'uint256' },
      { name: 'swapFee', type: 'uint24' },
    ],
    name: 'swapCollateral',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'asset', type: 'address' }],
    name: 'isCollateralSupported',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'getSupportedCollaterals',
    outputs: [{ name: '', type: 'address[]' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'getFlashLoanPremium',
    outputs: [{ name: '', type: 'uint128' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const;
