'use client';

import { useEffect, useMemo, useState } from 'react';
import { useAccount, useChainId, usePublicClient } from 'wagmi';
import { Address, Hex, formatUnits } from 'viem';
import { getAddresses, collateralSwapAbi, getTokenByAddress } from '@/config/contracts';

export interface SwapRecord {
  txHash: Hex;
  logIndex: number;
  chainId: number;
  timestamp: number | null;
  user: Address;
  sourceAsset: Address;
  targetAsset: Address;
  sourceAmount: bigint;
  targetAmount: bigint;
  flashLoanFee: bigint;
}

export interface AnalyticsSummary {
  totalSwaps: number;
  uniqueUsers: number;
  chainsUsed: number;
  totalSourceVolume: string;
}

export interface UseAnalyticsResult {
  swaps: SwapRecord[];
  summary: AnalyticsSummary;
  isLoading: boolean;
  error: string | null;
}

// Simple helper to safely get block timestamp
async function getBlockTimestamp(
  publicClient: ReturnType<typeof usePublicClient> extends infer T ? T : never,
  blockNumber: bigint | undefined,
): Promise<number | null> {
  if (!publicClient || blockNumber == null) return null;
  try {
    const block = await publicClient.getBlock({ blockNumber });
    return Number(block.timestamp);
  } catch {
    return null;
  }
}

export function useAnalytics(): UseAnalyticsResult {
  const { address: userAddress, isConnected } = useAccount();
  const chainId = useChainId();
  const publicClient = usePublicClient();
  const addresses = getAddresses(chainId);

  const [swaps, setSwaps] = useState<SwapRecord[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      if (!publicClient || !addresses.COLLATERAL_SWAP) return;
      if (!isConnected || !userAddress) {
        setSwaps([]);
        return;
      }

      setIsLoading(true);
      setError(null);

      try {
        // On mainnet RPCs (Alchemy free tier, etc.) eth_getLogs is restricted to a small block range.
        // For local fork testing, we only need to look at the most recent blocks where our txs live.
        const latest = await publicClient.getBlockNumber();
        // Use a small sliding window so we always capture recent swaps without hitting RPC limits.
        const window = 9n; // <= 10-block range for free tier providers
        const fromBlock = latest > window ? latest - window : 0n;

        const logs = await publicClient.getLogs({
          address: addresses.COLLATERAL_SWAP,
          events: [
            {
              type: 'event',
              name: 'CollateralSwapped',
              inputs: collateralSwapAbi.find(
                (f: any) => f.type === 'event' && f.name === 'CollateralSwapped',
              )?.inputs as any,
            } as any,
          ],
          fromBlock,
          toBlock: latest,
        });

        const parsed: SwapRecord[] = [];

        for (const log of logs as any[]) {
          // Parsed event logs will have `args`
          const args = (log as any).args || [];
          // Filter to current user only for now
          const user = (args.user || args[0]) as Address;
          if (!user || user.toLowerCase() !== userAddress!.toLowerCase()) continue;

          const record: SwapRecord = {
            txHash: log.transactionHash!,
            logIndex: Number(log.logIndex ?? 0n),
            chainId,
            timestamp: null, // filled below
            user,
            sourceAsset: (args.sourceAsset || args[1]) as Address,
            targetAsset: (args.targetAsset || args[2]) as Address,
            sourceAmount: (args.sourceAmount || args[3]) as bigint,
            targetAmount: (args.targetAmount || args[4]) as bigint,
            flashLoanFee: (args.flashLoanFee || args[5]) as bigint,
          };
          parsed.push(record);
        }

        // Attach timestamps (best-effort)
        const withTimestamps: SwapRecord[] = [];
        for (const rec of parsed) {
          const ts = await getBlockTimestamp(
            publicClient,
            // viem log has blockNumber as bigint
            (logs.find(
              (l) => l.transactionHash === rec.txHash && Number(l.logIndex ?? 0n) === rec.logIndex,
            ) as any)?.blockNumber,
          );
          withTimestamps.push({ ...rec, timestamp: ts });
        }

        if (!cancelled) {
          // Sort newest first
          withTimestamps.sort(
            (a, b) => (b.timestamp ?? 0) - (a.timestamp ?? 0) || b.logIndex - a.logIndex,
          );
          setSwaps(withTimestamps);
        }
      } catch (err: any) {
        console.error('[useAnalytics] Error loading swaps', err);
        if (!cancelled) {
          setError(err?.shortMessage || err?.message || 'Failed to load analytics');
        }
      } finally {
        if (!cancelled) setIsLoading(false);
      }
    }

    load();

    return () => {
      cancelled = true;
    };
  }, [publicClient, chainId, isConnected, userAddress]);

  const summary: AnalyticsSummary = useMemo(() => {
    if (!swaps.length) {
      return {
        totalSwaps: 0,
        uniqueUsers: 0,
        chainsUsed: 0,
        totalSourceVolume: '0',
      };
    }

    const users = new Set<string>();
    const chains = new Set<number>();
    let totalVolume = 0n;

    for (const s of swaps) {
      users.add(s.user.toLowerCase());
      chains.add(s.chainId);
      totalVolume += s.sourceAmount;
    }

    // Assume WETH decimals for formatting volume for now (18); this is just a rough KPI.
    const totalSourceVolume = formatUnits(totalVolume, 18);

    return {
      totalSwaps: swaps.length,
      uniqueUsers: users.size,
      chainsUsed: chains.size,
      totalSourceVolume,
    };
  }, [swaps]);

  return {
    swaps,
    summary,
    isLoading,
    error,
  };
}

