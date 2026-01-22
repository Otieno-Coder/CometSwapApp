import { SwapCard } from '@/components/SwapCard';
import { Stats } from '@/components/Stats';
import { PositionCard } from '@/components/PositionCard';

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-mesh">
      {/* Hero Section */}
      <div className="container mx-auto px-4 pt-8 pb-4">
        <div className="text-center max-w-2xl mx-auto mb-8">
          <h1 className="text-4xl md:text-5xl font-bold mb-4">
            <span className="bg-gradient-to-r from-emerald-400 via-cyan-400 to-blue-400 bg-clip-text text-transparent">
              Collateral Swap
            </span>
          </h1>
          <p className="text-slate-400 text-lg">
            Atomically swap your Compound V3 collateral without exiting your position.
            Powered by Aave flash loans and Uniswap V3.
          </p>
        </div>
      </div>

      {/* Main Content */}
      <div className="container mx-auto px-4 pb-16">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 max-w-6xl mx-auto">
          {/* Left Column - Swap */}
          <div className="lg:col-span-5">
            <SwapCard />
          </div>

          {/* Right Column - Stats & Position */}
          <div className="lg:col-span-7 space-y-6">
            <Stats />
            <PositionCard />
          </div>
        </div>

        {/* How It Works */}
        <div className="max-w-6xl mx-auto mt-16">
          <h2 className="text-2xl font-bold text-white mb-8 text-center">How It Works</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <StepCard
              number={1}
              title="Select Tokens"
              description="Choose which collateral to swap from and to"
              icon={
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                </svg>
              }
            />
            <StepCard
              number={2}
              title="Flash Borrow"
              description="Aave lends target collateral instantly"
              icon={
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              }
            />
            <StepCard
              number={3}
              title="Atomic Swap"
              description="Supply, withdraw, and swap in one transaction"
              icon={
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
              }
            />
            <StepCard
              number={4}
              title="Position Updated"
              description="Your collateral is swapped atomically"
              icon={
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              }
            />
          </div>
        </div>

        {/* Features */}
        <div className="max-w-6xl mx-auto mt-16">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <FeatureCard
              title="No Protocol Fees"
              description="Only pay flash loan fees (0.05%) and swap fees. No extra charges."
              gradient="from-emerald-500 to-cyan-500"
            />
            <FeatureCard
              title="Atomic Execution"
              description="All steps happen in one transaction. If any step fails, everything reverts."
              gradient="from-cyan-500 to-blue-500"
            />
            <FeatureCard
              title="Stay Collateralized"
              description="Swap collateral without closing your position or risking liquidation."
              gradient="from-blue-500 to-purple-500"
            />
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="border-t border-slate-800 py-8">
        <div className="container mx-auto px-4 text-center text-slate-500 text-sm">
          <p>Built for the Compound Grants Program</p>
          <p className="mt-2">
            <a href="https://github.com" className="hover:text-emerald-400 transition-colors">GitHub</a>
            {' · '}
            <a href="https://docs.compound.finance" className="hover:text-emerald-400 transition-colors">Docs</a>
          </p>
        </div>
      </footer>
    </div>
  );
}

// ============ Sub-components ============

interface StepCardProps {
  number: number;
  title: string;
  description: string;
  icon: React.ReactNode;
}

function StepCard({ number, title, description, icon }: StepCardProps) {
  return (
    <div className="relative p-6 bg-slate-800/50 rounded-2xl border border-slate-700/50 group hover:border-emerald-500/30 transition-colors">
      <div className="absolute -top-3 -left-3 w-8 h-8 rounded-full bg-gradient-to-br from-emerald-400 to-cyan-400 flex items-center justify-center text-sm font-bold text-slate-900">
        {number}
      </div>
      <div className="text-emerald-400 mb-3">{icon}</div>
      <h3 className="font-semibold text-white mb-1">{title}</h3>
      <p className="text-sm text-slate-400">{description}</p>
    </div>
  );
}

interface FeatureCardProps {
  title: string;
  description: string;
  gradient: string;
}

function FeatureCard({ title, description, gradient }: FeatureCardProps) {
  return (
    <div className="p-6 bg-slate-800/50 rounded-2xl border border-slate-700/50 hover:border-slate-600/50 transition-colors">
      <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${gradient} opacity-20 mb-4`} />
      <h3 className="font-semibold text-white mb-2">{title}</h3>
      <p className="text-sm text-slate-400">{description}</p>
    </div>
  );
}
