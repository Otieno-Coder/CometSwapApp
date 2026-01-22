import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'wagmi';
import { mainnet, sepolia } from 'wagmi/chains';

// WalletConnect Project ID - Get one at https://cloud.walletconnect.com
const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'YOUR_PROJECT_ID';

// In development, point mainnet RPC to local Anvil fork so the UI
// sees the same state (positions, balances) as your fork.
const localForkRpc = process.env.NEXT_PUBLIC_MAINNET_RPC_URL || 'http://127.0.0.1:8545';

export const wagmiConfig = getDefaultConfig({
  appName: 'CometSwap',
  projectId,
  chains: [mainnet, sepolia],
  transports: {
    [mainnet.id]: http(localForkRpc),
    [sepolia.id]: http(),
  },
  ssr: true,
});
