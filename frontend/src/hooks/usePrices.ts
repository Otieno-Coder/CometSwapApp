'use client';

import { useEffect, useState } from 'react';
import { Address } from 'viem';
import { usePublicClient } from 'wagmi';
import { getPriceFeed, priceFeedAbi } from '@/config/prices';

export interface TokenPrice {
  token: Address;
  priceUsd: number; // 1 token in USD
}

export function useTokenPrices(tokens: Address[]) {
  const publicClient = usePublicClient();
  const [prices, setPrices] = useState<Record<string, TokenPrice>>({});
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      if (!publicClient || tokens.length === 0) return;
      setIsLoading(true);

      try {
        const entries: [string, TokenPrice][] = [];

        for (const token of tokens) {
          const cfg = getPriceFeed(token);
          if (!cfg) continue;

          const answer = (await publicClient.readContract({
            address: cfg.feed,
            abi: priceFeedAbi,
            functionName: 'latestAnswer',
          })) as bigint;

          // Chainlink answers are 1e8 by default (decimals in cfg.decimals)
          const priceRaw = Number(answer) / 10 ** cfg.decimals;

          entries.push([
            token.toLowerCase(),
            {
              token,
              priceUsd: priceRaw,
            },
          ]);
        }

        if (!cancelled) {
          const map: Record<string, TokenPrice> = {};
          for (const [k, v] of entries) map[k] = v;
          setPrices(map);
        }
      } catch (e) {
        console.error('[useTokenPrices] error loading prices', e);
      } finally {
        if (!cancelled) setIsLoading(false);
      }
    }

    load();

    return () => {
      cancelled = true;
    };
  }, [publicClient, JSON.stringify(tokens)]);

  return { prices, isLoading };
}

