import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'wagmi';
import { mainnet, sepolia } from 'wagmi/chains';

// WalletConnect Project ID - Get one at https://cloud.walletconnect.com
const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'YOUR_PROJECT_ID';

// RPC Configuration
// In development, point mainnet RPC to local Anvil fork so the UI
// sees the same state (positions, balances) as your fork.
// In production, use a public RPC or your own RPC endpoint.
const getMainnetRpc = () => {
  if (process.env.NEXT_PUBLIC_MAINNET_RPC_URL) {
    return process.env.NEXT_PUBLIC_MAINNET_RPC_URL;
  }
  // In production, use public RPC. In development, use local fork.
  if (process.env.NODE_ENV === 'production') {
    return 'https://eth.llamarpc.com'; // Public RPC fallback
  }
  return 'http://127.0.0.1:8545'; // Local Anvil fork
};

export const wagmiConfig = getDefaultConfig({
  appName: 'CometSwap',
  projectId,
  chains: [mainnet, sepolia],
  transports: {
    [mainnet.id]: http(getMainnetRpc()),
    [sepolia.id]: http(),
  },
  ssr: true,
});
