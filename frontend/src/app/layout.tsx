import type { Metadata } from 'next';
import { Space_Grotesk } from 'next/font/google';
import './globals.css';
import '@rainbow-me/rainbowkit/styles.css';
import { Providers } from './providers';
import { Header } from '@/components/Header';

const spaceGrotesk = Space_Grotesk({ 
  subsets: ['latin'],
  variable: '--font-space-grotesk',
});

export const metadata: Metadata = {
  title: 'CometSwap - Collateral Swap for Compound V3',
  description: 'Atomically swap your Compound V3 collateral without exiting your position. Powered by Aave flash loans and Uniswap V3.',
  keywords: ['DeFi', 'Compound', 'Collateral', 'Swap', 'Flash Loans', 'Ethereum'],
  themeColor: '#22c55e',
  manifest: '/manifest.json',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={spaceGrotesk.variable}>
      <body className="font-sans antialiased">
        <Providers>
          <Header />
          {children}
        </Providers>
      </body>
    </html>
  );
}
