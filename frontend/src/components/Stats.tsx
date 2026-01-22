'use client';

import React from 'react';
import { useAccount } from 'wagmi';
import { useComet, useCometPosition } from '@/hooks/useComet';

export function Stats() {
  const { address, isConnected } = useAccount();
  const { protocolStats } = useComet();
  const { position, isLoading } = useCometPosition();

  return (
    <div className="bg-gradient-to-br from-slate-800 to-slate-900 rounded-2xl border border-slate-700/50 shadow-xl overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 border-b border-slate-700/50">
        <h2 className="text-xl font-semibold text-white flex items-center gap-2">
          <span className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse" />
          Protocol Stats
        </h2>
      </div>

      {/* Protocol Stats */}
      <div className="p-6 space-y-6">
        <div className="grid grid-cols-2 gap-4">
          <StatCard
            label="Supply APR"
            value={`${protocolStats.supplyApr.toFixed(2)}%`}
            color="emerald"
          />
          <StatCard
            label="Borrow APR"
            value={`${protocolStats.borrowApr.toFixed(2)}%`}
            color="amber"
          />
          <StatCard
            label="Utilization"
            value={`${protocolStats.utilization.toFixed(1)}%`}
            color="blue"
          />
          <StatCard
            label="Base Asset"
            value={protocolStats.baseToken}
            color="purple"
          />
        </div>

        {/* User Position */}
        {isConnected && (
          <>
            <div className="border-t border-slate-700/50 pt-6">
              <h3 className="text-sm font-medium text-slate-400 mb-4">Your Position</h3>
              
              {isLoading ? (
                <div className="flex items-center justify-center py-8">
                  <div className="w-6 h-6 border-2 border-emerald-400 border-t-transparent rounded-full animate-spin" />
                </div>
              ) : (
                <div className="space-y-4">
                  {/* Supply/Borrow Balance */}
                  <div className="grid grid-cols-2 gap-4">
                    <div className="bg-slate-800/50 rounded-xl p-4">
                      <p className="text-xs text-slate-400 mb-1">Supply Balance</p>
                      <p className="text-lg font-semibold text-emerald-400">
                        ${parseFloat(position.supplyBalanceFormatted).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                      </p>
                    </div>
                    <div className="bg-slate-800/50 rounded-xl p-4">
                      <p className="text-xs text-slate-400 mb-1">Borrow Balance</p>
                      <p className="text-lg font-semibold text-amber-400">
                        ${parseFloat(position.borrowBalanceFormatted).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                      </p>
                    </div>
                  </div>

                  {/* Health Indicator */}
                  <div className="bg-slate-800/50 rounded-xl p-4">
                    <div className="flex items-center justify-between mb-2">
                      <p className="text-xs text-slate-400">Health Status</p>
                      <HealthBadge 
                        isLiquidatable={position.isLiquidatable} 
                        hasCollateral={position.collaterals.length > 0}
                      />
                    </div>
                    <div className="w-full bg-slate-700 rounded-full h-2">
                      <div 
                        className={`h-2 rounded-full transition-all duration-500 ${
                          position.isLiquidatable 
                            ? 'bg-red-500' 
                            : position.collaterals.length > 0 
                              ? 'bg-emerald-500' 
                              : 'bg-slate-600'
                        }`}
                        style={{ width: position.collaterals.length > 0 ? '85%' : '0%' }}
                      />
                    </div>
                  </div>

                  {/* Collateral Count */}
                  {position.collaterals.length > 0 && (
                    <div className="text-center text-sm text-slate-400">
                      <span className="text-emerald-400 font-medium">{position.collaterals.length}</span> active collateral{position.collaterals.length !== 1 ? 's' : ''}
                    </div>
                  )}
                </div>
              )}
            </div>
          </>
        )}

        {/* Not Connected */}
        {!isConnected && (
          <div className="border-t border-slate-700/50 pt-6">
            <div className="text-center py-4">
              <p className="text-slate-400 text-sm">Connect wallet to view your position</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ============ Sub-components ============

interface StatCardProps {
  label: string;
  value: string;
  color: 'emerald' | 'amber' | 'blue' | 'purple';
}

function StatCard({ label, value, color }: StatCardProps) {
  const colorClasses = {
    emerald: 'text-emerald-400',
    amber: 'text-amber-400',
    blue: 'text-blue-400',
    purple: 'text-purple-400',
  };

  return (
    <div className="bg-slate-800/50 rounded-xl p-4">
      <p className="text-xs text-slate-400 mb-1">{label}</p>
      <p className={`text-lg font-semibold ${colorClasses[color]}`}>{value}</p>
    </div>
  );
}

interface HealthBadgeProps {
  isLiquidatable: boolean;
  hasCollateral: boolean;
}

function HealthBadge({ isLiquidatable, hasCollateral }: HealthBadgeProps) {
  if (!hasCollateral) {
    return (
      <span className="px-2 py-1 text-xs font-medium rounded-full bg-slate-700 text-slate-400">
        No Position
      </span>
    );
  }

  if (isLiquidatable) {
    return (
      <span className="px-2 py-1 text-xs font-medium rounded-full bg-red-500/20 text-red-400 animate-pulse">
        At Risk
      </span>
    );
  }

  return (
    <span className="px-2 py-1 text-xs font-medium rounded-full bg-emerald-500/20 text-emerald-400">
      Healthy
    </span>
  );
}
