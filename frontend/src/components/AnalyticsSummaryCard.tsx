'use client';

import { useAnalytics } from '@/hooks';

export function AnalyticsSummaryCard() {
  const { swaps, summary, isLoading } = useAnalytics();

  if (isLoading) {
    return (
      <div className="rounded-2xl border border-slate-700/60 bg-slate-900/60 p-4 flex items-center justify-between">
        <div>
          <p className="text-xs text-slate-400 mb-1">Recent Activity</p>
          <p className="text-sm text-slate-300">Loading your recent swaps...</p>
        </div>
        <div className="w-6 h-6 border-2 border-emerald-400 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!swaps.length) {
    return (
      <div className="rounded-2xl border border-slate-700/60 bg-slate-900/60 p-4">
        <p className="text-xs text-slate-400 mb-1">Recent Activity</p>
        <p className="text-sm text-slate-300">No swaps yet. Your first swap will appear here.</p>
      </div>
    );
  }

  const recent = swaps.slice(0, 5);

  return (
    <div className="rounded-2xl border border-slate-700/60 bg-slate-900/60 p-4">
      <div className="flex items-center justify-between mb-2">
        <p className="text-xs text-slate-400">Recent Activity</p>
        <p className="text-[11px] text-slate-500">
          {summary.totalSwaps} swap{summary.totalSwaps === 1 ? '' : 's'} total
        </p>
      </div>
      <div className="space-y-1.5">
        {recent.map((swap) => (
          <div
            key={`${swap.txHash}-${swap.logIndex}`}
            className="flex items-center justify-between text-xs text-slate-300"
          >
            <span className="truncate max-w-[60%]">
              {swap.sourceAsset.slice(0, 6)}… → {swap.targetAsset.slice(0, 6)}…
            </span>
            <span className="text-slate-500">
              {swap.timestamp ? new Date(swap.timestamp * 1000).toLocaleTimeString() : ''}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

