'use client';

import { useReadContract, useReadContracts, useAccount } from 'wagmi';
import { formatUnits } from 'viem';
import { addresses, cometAbi, cometCollaterals, TokenInfo, getTokenByAddress } from '@/config/contracts';

// ============ Types ============
export interface CollateralPosition {
  token: TokenInfo;
  balance: bigint;
  balanceFormatted: string;
  valueUsd: number;
  borrowCollateralFactor: number;
  liquidateCollateralFactor: number;
}

export interface CometPosition {
  collaterals: CollateralPosition[];
  borrowBalance: bigint;
  borrowBalanceFormatted: string;
  supplyBalance: bigint;
  supplyBalanceFormatted: string;
  isLiquidatable: boolean;
  isBorrowCollateralized: boolean;
  totalCollateralValueUsd: number;
  borrowingPowerUsd: number;
  healthFactor: number;
}

export interface CometProtocolStats {
  utilization: number;
  supplyApr: number;
  borrowApr: number;
  baseToken: string;
}

// ============ Hook: useComet ============
export function useComet() {
  const { address: userAddress, isConnected } = useAccount();

  // Read protocol stats
  const { data: utilization } = useReadContract({
    address: addresses.COMET_USDC,
    abi: cometAbi,
    functionName: 'getUtilization',
  });

  const { data: supplyRate } = useReadContract({
    address: addresses.COMET_USDC,
    abi: cometAbi,
    functionName: 'getSupplyRate',
    args: [utilization ?? 0n],
    query: { enabled: !!utilization },
  });

  const { data: borrowRate } = useReadContract({
    address: addresses.COMET_USDC,
    abi: cometAbi,
    functionName: 'getBorrowRate',
    args: [utilization ?? 0n],
    query: { enabled: !!utilization },
  });

  // Calculate APRs (rate per second * seconds per year)
  const secondsPerYear = 365n * 24n * 60n * 60n;
  const supplyApr = supplyRate ? Number(supplyRate * secondsPerYear) / 1e18 * 100 : 0;
  const borrowApr = borrowRate ? Number(borrowRate * secondsPerYear) / 1e18 * 100 : 0;

  const protocolStats: CometProtocolStats = {
    utilization: utilization ? Number(utilization) / 1e18 * 100 : 0,
    supplyApr,
    borrowApr,
    baseToken: 'USDC',
  };

  return {
    protocolStats,
    isConnected,
  };
}

// ============ Hook: useCometPosition ============
export function useCometPosition() {
  const { address: userAddress, isConnected } = useAccount();

  // Build contract reads for all collateral balances
  const collateralReads = cometCollaterals.map((token) => ({
    address: addresses.COMET_USDC,
    abi: cometAbi,
    functionName: 'collateralBalanceOf',
    args: [userAddress!, token.address],
  }));

  // Read all collateral balances in one call
  const { data: collateralBalances, isLoading: collateralsLoading, refetch: refetchCollaterals } = useReadContracts({
    contracts: collateralReads as any,
    query: { enabled: isConnected && !!userAddress },
  });

  // Read borrow balance
  const { data: borrowBalance, isLoading: borrowLoading } = useReadContract({
    address: addresses.COMET_USDC,
    abi: cometAbi,
    functionName: 'borrowBalanceOf',
    args: [userAddress!],
    query: { enabled: isConnected && !!userAddress },
  });

  // Read supply balance (base token)
  const { data: supplyBalance, isLoading: supplyLoading } = useReadContract({
    address: addresses.COMET_USDC,
    abi: cometAbi,
    functionName: 'balanceOf',
    args: [userAddress!],
    query: { enabled: isConnected && !!userAddress },
  });

  // Read liquidation status
  const { data: isLiquidatable } = useReadContract({
    address: addresses.COMET_USDC,
    abi: cometAbi,
    functionName: 'isLiquidatable',
    args: [userAddress!],
    query: { enabled: isConnected && !!userAddress },
  });

  const { data: isBorrowCollateralized } = useReadContract({
    address: addresses.COMET_USDC,
    abi: cometAbi,
    functionName: 'isBorrowCollateralized',
    args: [userAddress!],
    query: { enabled: isConnected && !!userAddress },
  });

  // Process collateral data
  const collaterals: CollateralPosition[] = cometCollaterals.map((token, index) => {
    const result = collateralBalances?.[index];
    const balance = result?.status === 'success' ? (result.result as bigint) : 0n;

    return {
      token,
      balance,
      balanceFormatted: formatUnits(balance, token.decimals),
      valueUsd: 0, // TODO: Fetch prices
      borrowCollateralFactor: 0.8, // Default, should fetch from contract
      liquidateCollateralFactor: 0.85,
    };
  }).filter(c => c.balance > 0n);

  const position: CometPosition = {
    collaterals,
    borrowBalance: borrowBalance ?? 0n,
    borrowBalanceFormatted: formatUnits(borrowBalance ?? 0n, 6), // USDC has 6 decimals
    supplyBalance: supplyBalance ?? 0n,
    supplyBalanceFormatted: formatUnits(supplyBalance ?? 0n, 6),
    isLiquidatable: isLiquidatable ?? false,
    isBorrowCollateralized: isBorrowCollateralized ?? true,
    totalCollateralValueUsd: 0, // TODO: Calculate from prices
    borrowingPowerUsd: 0,
    healthFactor: collaterals.length > 0 ? 999 : 0, // Placeholder
  };

  const isLoading = collateralsLoading || borrowLoading || supplyLoading;

  return {
    position,
    isLoading,
    isConnected,
    refetch: refetchCollaterals,
  };
}

// ============ Hook: useCometAllowance ============
export function useCometAllowance(managerAddress: `0x${string}` | undefined) {
  const { address: userAddress, isConnected } = useAccount();

  const { data: isAllowed, isLoading, refetch } = useReadContract({
    address: addresses.COMET_USDC,
    abi: cometAbi,
    functionName: 'isAllowed',
    args: [userAddress!, managerAddress!],
    query: { enabled: isConnected && !!userAddress && !!managerAddress },
  });

  return {
    isAllowed: isAllowed ?? false,
    isLoading,
    refetch,
  };
}
