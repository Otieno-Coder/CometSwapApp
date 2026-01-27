'use client';

import React from 'react';
import Image from 'next/image';
import { useAccount } from 'wagmi';
import { useCometPosition } from '@/hooks/useComet';
import type { CollateralPosition } from '@/hooks/useComet';

export function PositionCard() {
  const { isConnected } = useAccount();
  const { position, isLoading } = useCometPosition();

  if (!isConnected) {
    return null;
  }

  return (
    <div className="bg-gradient-to-br from-slate-800 to-slate-900 rounded-2xl border border-slate-700/50 shadow-xl overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 border-b border-slate-700/50 flex items-center justify-between">
        <h2 className="text-xl font-semibold text-white">Your Collateral</h2>
        <span className="text-xs text-slate-400 bg-slate-800 px-3 py-1 rounded-full">
          Compound V3
        </span>
      </div>

      {/* Content */}
      <div className="p-6">
        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="w-8 h-8 border-2 border-emerald-400 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : position.collaterals.length === 0 ? (
          <EmptyState />
        ) : (
          <div className="space-y-3">
            {position.collaterals.map((collateral) => (
              <CollateralRow key={collateral.token.address} collateral={collateral} />
            ))}
          </div>
        )}
      </div>

      {/* Footer - Only show if has collateral */}
      {position.collaterals.length > 0 && (
        <div className="px-6 py-4 border-t border-slate-700/50 bg-slate-800/30">
          <div className="flex items-center justify-between text-sm">
            <span className="text-slate-400">Total Collateral Assets</span>
            <span className="text-white font-medium">{position.collaterals.length}</span>
          </div>
        </div>
      )}
    </div>
  );
}

// ============ Sub-components ============

function EmptyState() {
  return (
    <div className="text-center py-8">
      <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-slate-800 flex items-center justify-center">
        <svg className="w-8 h-8 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
        </svg>
      </div>
      <h3 className="text-white font-medium mb-1">No Collateral</h3>
      <p className="text-slate-400 text-sm max-w-xs mx-auto">
        You don't have any collateral deposited in Compound V3 yet.
      </p>
      <a 
        href="https://app.compound.finance/" 
        target="_blank" 
        rel="noopener noreferrer"
        className="inline-flex items-center gap-1 mt-4 text-sm text-emerald-400 hover:text-emerald-300 transition-colors"
      >
        Deposit on Compound
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
        </svg>
      </a>
    </div>
  );
}

interface CollateralRowProps {
  collateral: CollateralPosition;
}

function CollateralRow({ collateral }: CollateralRowProps) {
  const { token, balanceFormatted, valueUsd } = collateral;
  const displayBalance = parseFloat(balanceFormatted);

  return (
    <div className="flex items-center justify-between p-4 bg-slate-800/50 rounded-xl hover:bg-slate-800/70 transition-colors group">
      {/* Token Info */}
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-full bg-slate-700 flex items-center justify-center overflow-hidden">
          {token.logoUrl ? (
            <Image 
              src={token.logoUrl} 
              alt={token.symbol} 
              width={40} 
              height={40}
              className="rounded-full"
            />
          ) : (
            <span className="text-sm font-bold text-slate-400">
              {token.symbol.slice(0, 2)}
            </span>
          )}
        </div>
        <div>
          <p className="font-medium text-white">{token.symbol}</p>
          <p className="text-xs text-slate-400">{token.name}</p>
        </div>
      </div>

      {/* Balance */}
      <div className="text-right">
        <p className="font-medium text-white">
          {displayBalance.toLocaleString(undefined, { 
            minimumFractionDigits: 2, 
            maximumFractionDigits: token.decimals <= 8 ? 6 : 4 
          })}
        </p>
        <p className="text-xs text-slate-400">
          {token.symbol}
          {valueUsd > 0 && (
            <> · ${valueUsd.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</>
          )}
        </p>
      </div>
    </div>
  );
}
