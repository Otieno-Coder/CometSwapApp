'use client';

import { useAnalytics } from '@/hooks';
import { getTokenByAddress } from '@/config/contracts';

export default function AnalyticsPage() {
  const { swaps, summary, isLoading, error } = useAnalytics();

  return (
    <div className="min-h-screen bg-gradient-mesh">
      <div className="container mx-auto px-4 pt-8 pb-4">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-3xl md:text-4xl font-bold mb-2 text-center text-white">
            Analytics Dashboard
          </h1>
          <p className="text-slate-400 text-center mb-8">
            Historical view of your collateral swaps across supported chains.
          </p>

          {/* Summary cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
            <SummaryCard label="Total Swaps" value={summary.totalSwaps.toString()} />
            <SummaryCard label="Unique Users" value={summary.uniqueUsers.toString()} />
            <SummaryCard label="Chains Used" value={summary.chainsUsed.toString()} />
            <SummaryCard
              label="Total Source Volume"
              value={`${Number(summary.totalSourceVolume).toFixed(4)} (approx.)`}
            />
          </div>

          {isLoading && (
            <div className="flex items-center justify-center py-12">
              <div className="w-8 h-8 border-2 border-emerald-400 border-t-transparent rounded-full animate-spin" />
            </div>
          )}

          {error && (
            <div className="mb-6 rounded-xl border border-red-500/40 bg-red-500/10 px-4 py-3 text-sm text-red-200">
              {error}
            </div>
          )}

          {!isLoading && !error && swaps.length === 0 && (
            <div className="rounded-xl border border-slate-700/60 bg-slate-900/60 px-4 py-6 text-center text-slate-400">
              No swaps found yet. Execute a swap to see it appear here.
            </div>
          )}

          {!isLoading && swaps.length > 0 && (
            <div className="mt-4 rounded-xl border border-slate-700/60 bg-slate-900/60 overflow-hidden">
              <div className="overflow-x-auto">
                <table className="min-w-full text-sm">
                  <thead className="bg-slate-800/70 text-slate-300">
                    <tr>
                      <th className="px-4 py-3 text-left">Time</th>
                      <th className="px-4 py-3 text-left">Pair</th>
                      <th className="px-4 py-3 text-right">Source Amount</th>
                      <th className="px-4 py-3 text-right">Target Amount</th>
                      <th className="px-4 py-3 text-right">Chain</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800">
                    {swaps.map((swap) => {
                      const sourceToken = getTokenByAddress(swap.sourceAsset);
                      const targetToken = getTokenByAddress(swap.targetAsset);

                      const date = swap.timestamp
                        ? new Date(swap.timestamp * 1000).toLocaleString()
                        : 'Unknown';

                      return (
                        <tr key={`${swap.txHash}-${swap.logIndex}`} className="hover:bg-slate-800/40">
                          <td className="px-4 py-3 align-top text-slate-300">{date}</td>
                          <td className="px-4 py-3 align-top">
                            <div className="text-slate-100">
                              {sourceToken?.symbol ?? 'SRC'} → {targetToken?.symbol ?? 'TGT'}
                            </div>
                            <div className="text-[11px] text-slate-500 break-all">
                              {swap.txHash}
                            </div>
                          </td>
                          <td className="px-4 py-3 align-top text-right text-slate-200">
                            {sourceToken
                              ? Number(
                                  (swap.sourceAmount / BigInt(10 ** sourceToken.decimals)).toString(),
                                ).toFixed(4)
                              : swap.sourceAmount.toString()}
                          </td>
                          <td className="px-4 py-3 align-top text-right text-slate-200">
                            {targetToken
                              ? Number(
                                  (swap.targetAmount / BigInt(10 ** targetToken.decimals)).toString(),
                                ).toFixed(4)
                              : swap.targetAmount.toString()}
                          </td>
                          <td className="px-4 py-3 align-top text-right text-slate-400">
                            {swap.chainId}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

interface SummaryCardProps {
  label: string;
  value: string;
}

function SummaryCard({ label, value }: SummaryCardProps) {
  return (
    <div className="rounded-2xl border border-slate-700/70 bg-slate-900/60 px-4 py-3">
      <p className="text-xs text-slate-400 mb-1">{label}</p>
      <p className="text-lg font-semibold text-emerald-400 truncate">{value}</p>
    </div>
  );
}

