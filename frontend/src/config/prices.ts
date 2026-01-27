import { Address } from 'viem';
import { addresses } from './contracts';

// Simple Chainlink-style price feed ABI (latestAnswer / latestRoundData)
export const priceFeedAbi = [
  {
    inputs: [],
    name: 'latestAnswer',
    outputs: [{ internalType: 'int256', name: '', type: 'int256' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const;

export interface PriceFeedConfig {
  feed: Address;
  decimals: number;
}

// Mainnet price feeds for core tokens (Chainlink)
// NOTE: These are standard mainnet feeds; on a fork they resolve correctly.
export const priceFeeds: Record<Address, PriceFeedConfig> = {
  // ETH / USD
  // WETH uses ETH/USD
  [addresses.WETH]: {
    feed: '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419' as Address, // ETH / USD
    decimals: 8,
  },
  // WBTC / USD
  [addresses.WBTC]: {
    feed: '0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c' as Address, // BTC / USD
    decimals: 8,
  },
  // COMP / USD
  [addresses.COMP]: {
    feed: '0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5' as Address,
    decimals: 8,
  },
  // UNI / USD
  [addresses.UNI]: {
    feed: '0x553303d460EE0afB37EdFf9bE42922D8FF63220e' as Address,
    decimals: 8,
  },
  // LINK / USD
  [addresses.LINK]: {
    feed: '0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c' as Address,
    decimals: 8,
  },
} as const;

export function getPriceFeed(token: Address): PriceFeedConfig | undefined {
  return priceFeeds[token];
}

