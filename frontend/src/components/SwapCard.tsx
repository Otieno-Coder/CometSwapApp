'use client';

import React, { useState, useMemo, useEffect } from 'react';
import Image from 'next/image';
import { useAccount } from 'wagmi';
import { useCometPosition, useCometAllowance } from '@/hooks/useComet';
import { useUniswapQuote, useMinAmountOut } from '@/hooks/useUniswapQuote';
import { useCollateralSwap } from '@/hooks/useCollateralSwap';
import { useToast } from '@/components/Toast';
import { cometCollaterals, TokenInfo, addresses } from '@/config/contracts';

const FEE_TIER = 3000; // 0.3%
const SLIPPAGE_BPS = 100; // 1%

export function SwapCard() {
  const { isConnected } = useAccount();
  const { position, isLoading: positionLoading, refetch: refetchPosition } = useCometPosition();
  const { isAllowed, refetch: refetchAllowance } = useCometAllowance(addresses.COLLATERAL_SWAP);
  const { addToast, updateToast } = useToast();

  const [fromToken, setFromToken] = useState<TokenInfo | null>(null);
  const [toToken, setToToken] = useState<TokenInfo | null>(null);
  const [amount, setAmount] = useState('');
  const [showFromSelect, setShowFromSelect] = useState(false);
  const [showToSelect, setShowToSelect] = useState(false);

  // Get quote from Uniswap
  const quote = useUniswapQuote(fromToken, toToken, amount, FEE_TIER);
  const minAmountOut = useMinAmountOut(quote.amountOut, SLIPPAGE_BPS);

  // Swap execution hook
  const { 
    status: swapStatus, 
    error: swapError, 
    txHash,
    isContractDeployed,
    executeSwap,
    reset: resetSwap 
  } = useCollateralSwap();

  // Available tokens for "from" are only those the user has as collateral
  const availableFromTokens = useMemo(() => {
    return position.collaterals.map(c => c.token);
  }, [position.collaterals]);

  // Available tokens for "to" are all supported except the selected "from"
  const availableToTokens = useMemo(() => {
    return cometCollaterals.filter(t => t.address !== fromToken?.address);
  }, [fromToken]);

  // Get user's balance of selected from token
  const fromBalance = useMemo(() => {
    if (!fromToken) return '0';
    const collateral = position.collaterals.find(
      c => c.token.address.toLowerCase() === fromToken.address.toLowerCase()
    );
    return collateral?.balanceFormatted ?? '0';
  }, [fromToken, position.collaterals]);

  // Handle swap execution with toast notifications
  const handleSwap = async () => {
    if (!fromToken || !toToken || !amount) return;

    const toastId = addToast({
      type: 'loading',
      title: 'Initiating swap...',
      message: `Swapping ${amount} ${fromToken.symbol} → ${toToken.symbol}`,
    });

    const success = await executeSwap(
      fromToken,
      toToken,
      amount,
      minAmountOut,
      FEE_TIER
    );

    if (success) {
      updateToast(toastId, {
        type: 'success',
        title: 'Swap successful!',
        message: `Swapped ${amount} ${fromToken.symbol} → ${quote.amountOutFormatted} ${toToken.symbol}`,
        txHash: txHash ?? undefined,
      });
      
      // Reset form and refetch position
      setAmount('');
      refetchPosition();
      refetchAllowance();
    } else {
      updateToast(toastId, {
        type: 'error',
        title: 'Swap failed',
        message: swapError ?? 'Transaction was rejected or failed',
      });
    }

    resetSwap();
  };

  const handleFlip = () => {
    const temp = fromToken;
    setFromToken(toToken);
    setToToken(temp);
    setAmount('');
  };

  const handleMax = () => {
    setAmount(fromBalance);
  };

  const isValidSwap = fromToken && toToken && parseFloat(amount) > 0 && parseFloat(amount) <= parseFloat(fromBalance);
  const isSwapping = swapStatus === 'approving' || swapStatus === 'swapping';

  // Button state logic
  const getButtonConfig = () => {
    if (!isConnected) {
      return { text: 'Connect Wallet', disabled: true, variant: 'disabled' };
    }
    if (!isContractDeployed) {
      return { text: 'Contract Not Deployed', disabled: true, variant: 'disabled' };
    }
    if (!fromToken || !toToken) {
      return { text: 'Select tokens', disabled: true, variant: 'disabled' };
    }
    if (!amount || parseFloat(amount) <= 0) {
      return { text: 'Enter amount', disabled: true, variant: 'disabled' };
    }
    if (parseFloat(amount) > parseFloat(fromBalance)) {
      return { text: 'Insufficient balance', disabled: true, variant: 'disabled' };
    }
    if (quote.isLoading) {
      return { text: 'Fetching quote...', disabled: true, variant: 'disabled' };
    }
    if (quote.error) {
      return { text: quote.error, disabled: true, variant: 'error' };
    }
    if (isSwapping) {
      return { 
        text: swapStatus === 'approving' ? 'Approving...' : 'Swapping...', 
        disabled: true, 
        variant: 'loading' 
      };
    }
    if (!isAllowed && addresses.COLLATERAL_SWAP !== '0x0000000000000000000000000000000000000000') {
      return { text: 'Approve CometSwap', disabled: false, variant: 'approve' };
    }
    return { text: 'Swap Collateral', disabled: false, variant: 'swap' };
  };

  const buttonConfig = getButtonConfig();

  return (
    <div className="bg-gradient-to-br from-slate-800 to-slate-900 rounded-2xl border border-slate-700/50 shadow-2xl overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 border-b border-slate-700/50">
        <h2 className="text-xl font-semibold text-white">Swap Collateral</h2>
        <p className="text-sm text-slate-400 mt-1">
          Atomically swap between collateral types
        </p>
      </div>

      {/* Body */}
      <div className="p-6 space-y-4">
        {/* From Token */}
        <div className="relative">
          <label className="text-xs font-medium text-slate-400 mb-2 block">From</label>
          <div className="bg-slate-800/80 rounded-xl p-4 border border-slate-700/50 focus-within:border-emerald-500/50 transition-colors">
            <div className="flex items-center justify-between gap-4">
              {/* Token Selector */}
              <button
                onClick={() => setShowFromSelect(!showFromSelect)}
                className="flex items-center gap-2 px-3 py-2 rounded-xl bg-slate-700/50 hover:bg-slate-700 transition-colors min-w-[140px]"
                disabled={!isConnected || availableFromTokens.length === 0}
              >
                {fromToken ? (
                  <>
                    {fromToken.logoUrl && (
                      <Image src={fromToken.logoUrl} alt={fromToken.symbol} width={24} height={24} className="rounded-full" />
                    )}
                    <span className="font-medium text-white">{fromToken.symbol}</span>
                  </>
                ) : (
                  <span className="text-slate-400">Select token</span>
                )}
                <svg className="w-4 h-4 text-slate-400 ml-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </button>

              {/* Amount Input */}
              <div className="flex-1 text-right">
                <input
                  type="number"
                  placeholder="0.00"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="w-full bg-transparent text-2xl font-medium text-white text-right outline-none placeholder-slate-600"
                  disabled={!fromToken || isSwapping}
                />
                {fromToken && (
                  <div className="flex items-center justify-end gap-2 mt-1">
                    <span className="text-xs text-slate-400">
                      Balance: {parseFloat(fromBalance).toFixed(4)}
                    </span>
                    <button
                      onClick={handleMax}
                      className="text-xs font-medium text-emerald-400 hover:text-emerald-300"
                      disabled={isSwapping}
                    >
                      MAX
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Dropdown */}
          {showFromSelect && (
            <TokenDropdown
              tokens={availableFromTokens}
              onSelect={(token) => {
                setFromToken(token);
                setShowFromSelect(false);
              }}
              onClose={() => setShowFromSelect(false)}
            />
          )}
        </div>

        {/* Flip Button */}
        <div className="flex justify-center -my-2 relative z-10">
          <button
            onClick={handleFlip}
            disabled={isSwapping}
            className="w-10 h-10 rounded-xl bg-slate-700 hover:bg-slate-600 border border-slate-600 flex items-center justify-center transition-all hover:scale-110 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <svg className="w-5 h-5 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4" />
            </svg>
          </button>
        </div>

        {/* To Token */}
        <div className="relative">
          <label className="text-xs font-medium text-slate-400 mb-2 block">To</label>
          <div className="bg-slate-800/80 rounded-xl p-4 border border-slate-700/50 focus-within:border-emerald-500/50 transition-colors">
            <div className="flex items-center justify-between gap-4">
              {/* Token Selector */}
              <button
                onClick={() => setShowToSelect(!showToSelect)}
                className="flex items-center gap-2 px-3 py-2 rounded-xl bg-slate-700/50 hover:bg-slate-700 transition-colors min-w-[140px]"
                disabled={!isConnected || isSwapping}
              >
                {toToken ? (
                  <>
                    {toToken.logoUrl && (
                      <Image src={toToken.logoUrl} alt={toToken.symbol} width={24} height={24} className="rounded-full" />
                    )}
                    <span className="font-medium text-white">{toToken.symbol}</span>
                  </>
                ) : (
                  <span className="text-slate-400">Select token</span>
                )}
                <svg className="w-4 h-4 text-slate-400 ml-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </button>

              {/* Output (estimated) */}
              <div className="flex-1 text-right">
                <p className={`text-2xl font-medium ${quote.isLoading ? 'text-slate-500 animate-pulse' : quote.amountOut > 0n ? 'text-white' : 'text-slate-500'}`}>
                  {quote.isLoading ? '...' : quote.amountOutFormatted || '0.00'}
                </p>
                <p className="text-xs text-slate-500 mt-1">Estimated output</p>
              </div>
            </div>
          </div>

          {/* Dropdown */}
          {showToSelect && (
            <TokenDropdown
              tokens={availableToTokens}
              onSelect={(token) => {
                setToToken(token);
                setShowToSelect(false);
              }}
              onClose={() => setShowToSelect(false)}
            />
          )}
        </div>

        {/* Swap Details */}
        {fromToken && toToken && amount && parseFloat(amount) > 0 && (
          <div className="bg-slate-800/50 rounded-xl p-4 space-y-2">
            <DetailRow 
              label="Exchange Rate" 
              value={quote.isLoading ? 'Fetching...' : quote.exchangeRate} 
            />
            <DetailRow 
              label="Price Impact" 
              value={quote.isLoading ? '...' : `~${quote.priceImpact.toFixed(2)}%`} 
              highlight={quote.priceImpact > 1}
            />
            <DetailRow label="Flash Loan Fee" value="0.05%" />
            <DetailRow label="Slippage Tolerance" value="1.0%" />
            {quote.amountOut > 0n && (
              <DetailRow 
                label="Minimum Received" 
                value={`${(Number(minAmountOut) / Math.pow(10, toToken.decimals)).toFixed(6)} ${toToken.symbol}`}
              />
            )}
          </div>
        )}

        {/* Action Button */}
        <button
          onClick={handleSwap}
          disabled={buttonConfig.disabled}
          className={`w-full py-4 rounded-xl font-semibold text-lg transition-all ${
            buttonConfig.variant === 'disabled' || buttonConfig.variant === 'error'
              ? 'bg-slate-700 text-slate-400 cursor-not-allowed'
              : buttonConfig.variant === 'loading'
              ? 'bg-slate-700 text-slate-300 cursor-wait'
              : buttonConfig.variant === 'approve'
              ? 'bg-gradient-to-r from-amber-500 to-orange-500 text-white hover:from-amber-400 hover:to-orange-400 shadow-lg shadow-amber-500/25'
              : 'bg-gradient-to-r from-emerald-500 to-cyan-500 text-white hover:from-emerald-400 hover:to-cyan-400 shadow-lg shadow-emerald-500/25'
          }`}
        >
          {buttonConfig.variant === 'loading' && (
            <span className="inline-flex items-center gap-2">
              <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
              </svg>
              {buttonConfig.text}
            </span>
          )}
          {buttonConfig.variant !== 'loading' && buttonConfig.text}
        </button>

        {/* Info */}
        <p className="text-xs text-center text-slate-500">
          Powered by Aave Flash Loans + Uniswap V3
        </p>
      </div>
    </div>
  );
}

// ============ Sub-components ============

interface TokenDropdownProps {
  tokens: TokenInfo[];
  onSelect: (token: TokenInfo) => void;
  onClose: () => void;
}

function TokenDropdown({ tokens, onSelect, onClose }: TokenDropdownProps) {
  if (tokens.length === 0) {
    return (
      <div className="absolute top-full left-0 right-0 mt-2 bg-slate-800 rounded-xl border border-slate-700 shadow-xl z-20 p-4">
        <p className="text-sm text-slate-400 text-center">No tokens available</p>
      </div>
    );
  }

  return (
    <>
      {/* Backdrop */}
      <div className="fixed inset-0 z-10" onClick={onClose} />
      
      {/* Dropdown */}
      <div className="absolute top-full left-0 right-0 mt-2 bg-slate-800 rounded-xl border border-slate-700 shadow-xl z-20 max-h-60 overflow-y-auto">
        {tokens.map((token) => (
          <button
            key={token.address}
            onClick={() => onSelect(token)}
            className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-700/50 transition-colors"
          >
            {token.logoUrl && (
              <Image src={token.logoUrl} alt={token.symbol} width={32} height={32} className="rounded-full" />
            )}
            <div className="text-left">
              <p className="font-medium text-white">{token.symbol}</p>
              <p className="text-xs text-slate-400">{token.name}</p>
            </div>
          </button>
        ))}
      </div>
    </>
  );
}

interface DetailRowProps {
  label: string;
  value: string;
  highlight?: boolean;
}

function DetailRow({ label, value, highlight }: DetailRowProps) {
  return (
    <div className="flex items-center justify-between text-sm">
      <span className="text-slate-400">{label}</span>
      <span className={highlight ? 'text-amber-400' : 'text-slate-300'}>{value}</span>
    </div>
  );
}
