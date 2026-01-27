'use client';

import { useState, useCallback } from 'react';
import { useAccount, useWriteContract, usePublicClient, useChainId } from 'wagmi';
import { Address, parseUnits } from 'viem';
import { getAddresses, cometAbi, collateralSwapAbi, TokenInfo } from '@/config/contracts';

export type SwapStatus = 'idle' | 'approving' | 'swapping' | 'success' | 'error';

export interface SwapState {
  status: SwapStatus;
  error: string | null;
  txHash: `0x${string}` | null;
  approvalTxHash: `0x${string}` | null;
}

const DEFAULT_FEE_TIER = 3000; // 0.3%

export function useCollateralSwap() {
  const { address: userAddress, isConnected } = useAccount();
  const chainId = useChainId();
  const publicClient = usePublicClient();
  const addresses = getAddresses(chainId);
  
  const [swapState, setSwapState] = useState<SwapState>({
    status: 'idle',
    error: null,
    txHash: null,
    approvalTxHash: null,
  });

  const { writeContractAsync } = useWriteContract();

  // Check if CollateralSwap is allowed to manage user's Comet position
  const checkAllowance = useCallback(async (): Promise<boolean> => {
    if (!userAddress || !publicClient || addresses.COLLATERAL_SWAP === '0x0000000000000000000000000000000000000000') {
      return false;
    }

    try {
      const isAllowed = await publicClient.readContract({
        address: addresses.COMET_USDC,
        abi: cometAbi,
        functionName: 'isAllowed',
        args: [userAddress, addresses.COLLATERAL_SWAP],
      });
      return isAllowed as boolean;
    } catch (err) {
      console.error('Error checking allowance:', err);
      return false;
    }
  }, [userAddress, publicClient]);

  // Approve CollateralSwap to manage user's Comet position
  const approveManager = useCallback(async (): Promise<boolean> => {
    if (!userAddress || addresses.COLLATERAL_SWAP === '0x0000000000000000000000000000000000000000') {
      setSwapState(prev => ({ ...prev, error: 'CollateralSwap contract not deployed', status: 'error' }));
      return false;
    }

    setSwapState(prev => ({ ...prev, status: 'approving', error: null }));

    try {
      const hash = await writeContractAsync({
        address: addresses.COMET_USDC,
        abi: cometAbi,
        functionName: 'allow',
        args: [addresses.COLLATERAL_SWAP, true],
      });

      setSwapState(prev => ({ ...prev, approvalTxHash: hash }));

      // Wait for confirmation and ensure it didn't revert
      if (publicClient) {
        const receipt = await publicClient.waitForTransactionReceipt({ hash });
        if (receipt.status !== 'success') {
          throw new Error('Approval transaction reverted');
        }
      }

      return true;
    } catch (err: any) {
      console.error('Approval error:', err);
      setSwapState(prev => ({
        ...prev,
        status: 'error',
        error: err.shortMessage || err.message || 'Approval failed',
      }));
      return false;
    }
  }, [userAddress, writeContractAsync, publicClient]);

  // Execute the collateral swap
  const executeSwap = useCallback(async (
    sourceToken: TokenInfo,
    targetToken: TokenInfo,
    sourceAmount: string,
    minTargetAmount: bigint,
    feeTier: number = DEFAULT_FEE_TIER
  ): Promise<boolean> => {
    if (!userAddress || !publicClient) {
      setSwapState(prev => ({ ...prev, error: 'Wallet not connected', status: 'error' }));
      return false;
    }

    if (addresses.COLLATERAL_SWAP === '0x0000000000000000000000000000000000000000') {
      setSwapState(prev => ({ ...prev, error: 'CollateralSwap contract not deployed yet', status: 'error' }));
      return false;
    }

    // First check/do approval
    const isAllowed = await checkAllowance();
    if (!isAllowed) {
      const approved = await approveManager();
      if (!approved) return false;
    }

    setSwapState(prev => ({ ...prev, status: 'swapping', error: null }));

    try {
      const sourceAmountWei = parseUnits(sourceAmount, sourceToken.decimals);

      const hash = await writeContractAsync({
        address: addresses.COLLATERAL_SWAP,
        abi: collateralSwapAbi,
        functionName: 'swapCollateral',
        args: [
          sourceToken.address,
          targetToken.address,
          sourceAmountWei,
          minTargetAmount,
          feeTier,
        ],
      });

      setSwapState(prev => ({ ...prev, txHash: hash }));

      // Wait for confirmation and ensure it didn't revert
      const receipt = await publicClient.waitForTransactionReceipt({ hash });
      if (receipt.status !== 'success') {
        throw new Error('Swap transaction reverted');
      }

      setSwapState(prev => ({ ...prev, status: 'success' }));
      return true;
    } catch (err: any) {
      console.error('Swap error:', err);
      setSwapState(prev => ({
        ...prev,
        status: 'error',
        error: err.shortMessage || err.message || 'Swap failed',
      }));
      return false;
    }
  }, [userAddress, publicClient, writeContractAsync, checkAllowance, approveManager]);

  // Reset state
  const reset = useCallback(() => {
    setSwapState({
      status: 'idle',
      error: null,
      txHash: null,
      approvalTxHash: null,
    });
  }, []);

  return {
    ...swapState,
    isConnected,
    isContractDeployed: addresses.COLLATERAL_SWAP !== '0x0000000000000000000000000000000000000000',
    checkAllowance,
    approveManager,
    executeSwap,
    reset,
  };
}
