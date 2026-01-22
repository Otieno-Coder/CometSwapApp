'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { TokenInfo } from '@/config/contracts';

export interface QuoteResult {
  amountOut: bigint;
  amountOutFormatted: string;
  priceImpact: number;
  exchangeRate: string;
  gasEstimate: bigint;
  isLoading: boolean;
  error: string | null;
}

const DEFAULT_FEE = 3000; // 0.3% fee tier
const DEBOUNCE_MS = 300;

// Mock exchange rates for demo (in production, fetch from Uniswap Quoter)
const MOCK_PRICES: Record<string, number> = {
  'WETH': 3200,    // USD value
  'WBTC': 97000,   // USD value  
  'COMP': 85,      // USD value
  'UNI': 12,       // USD value
  'LINK': 18,      // USD value
  'USDC': 1,       // USD value
};

export function useUniswapQuote(
  tokenIn: TokenInfo | null,
  tokenOut: TokenInfo | null,
  amountIn: string,
  feeTier: number = DEFAULT_FEE
): QuoteResult {
  const [quote, setQuote] = useState<QuoteResult>({
    amountOut: 0n,
    amountOutFormatted: '0',
    priceImpact: 0,
    exchangeRate: '-',
    gasEstimate: 0n,
    isLoading: false,
    error: null,
  });

  // Calculate quote using mock prices (in production, use Uniswap Quoter)
  const calculateQuote = useCallback(() => {
    if (!tokenIn || !tokenOut || !amountIn || parseFloat(amountIn) <= 0) {
      setQuote({
        amountOut: 0n,
        amountOutFormatted: '0',
        priceImpact: 0,
        exchangeRate: '-',
        gasEstimate: 0n,
        isLoading: false,
        error: null,
      });
      return;
    }

    setQuote(prev => ({ ...prev, isLoading: true }));

    // Simulate a small delay like a real API call
    setTimeout(() => {
      try {
        const inputAmount = parseFloat(amountIn);
        const priceIn = MOCK_PRICES[tokenIn.symbol] ?? 1;
        const priceOut = MOCK_PRICES[tokenOut.symbol] ?? 1;

        // Calculate exchange: (inputAmount * priceIn) / priceOut
        const usdValue = inputAmount * priceIn;
        const outputAmount = usdValue / priceOut;

        // Apply a small fee (0.3% + 0.05% flash loan)
        const outputAfterFees = outputAmount * 0.9965;

        // Convert to bigint for the output token's decimals
        const outputBigInt = BigInt(Math.floor(outputAfterFees * Math.pow(10, tokenOut.decimals)));

        // Calculate exchange rate
        const rate = priceIn / priceOut;
        const exchangeRate = `1 ${tokenIn.symbol} = ${rate.toFixed(6)} ${tokenOut.symbol}`;

        // Estimate price impact (simplified)
        const priceImpact = inputAmount > 10 ? 0.3 : 0.1;

        setQuote({
          amountOut: outputBigInt,
          amountOutFormatted: outputAfterFees.toFixed(6),
          priceImpact,
          exchangeRate,
          gasEstimate: 250000n, // Estimated gas
          isLoading: false,
          error: null,
        });
      } catch (err: any) {
        setQuote(prev => ({
          ...prev,
          amountOut: 0n,
          amountOutFormatted: '0',
          isLoading: false,
          error: 'Failed to calculate quote',
        }));
      }
    }, DEBOUNCE_MS);
  }, [tokenIn, tokenOut, amountIn]);

  // Recalculate when inputs change
  useEffect(() => {
    calculateQuote();
  }, [calculateQuote]);

  return quote;
}

// Hook for calculating minimum output with slippage
export function useMinAmountOut(amountOut: bigint, slippageBps: number = 100): bigint {
  return useMemo(() => {
    // slippageBps: 100 = 1%, 50 = 0.5%
    if (amountOut === 0n) return 0n;
    const slippageMultiplier = 10000n - BigInt(slippageBps);
    return (amountOut * slippageMultiplier) / 10000n;
  }, [amountOut, slippageBps]);
}

// Calculate flash loan fee
export function useFlashLoanFee(amount: bigint): bigint {
  return useMemo(() => {
    // Aave V3 flash loan fee is 0.05% (5 basis points)
    return (amount * 5n) / 10000n;
  }, [amount]);
}
