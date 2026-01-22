# Vercel Deployment Instructions

## Quick Fix for Output Directory Issue

The build is successful, but Vercel needs to know where the Next.js app is located.

### Option 1: Configure in Vercel Dashboard (Recommended)

1. Go to your Vercel project: https://vercel.com/dashboard
2. Click on your project → **Settings**
3. Navigate to **General** → **Root Directory**
4. Set Root Directory to: `frontend`
5. Click **Save**
6. Redeploy

This tells Vercel to treat the `frontend/` directory as the project root, so it will automatically find `.next` in the correct location.

### Option 2: Keep Current Setup

The current `vercel.json` should work, but if you still get errors, try Option 1 above.

## Environment Variables

Add these in Vercel Dashboard → Settings → Environment Variables:

- `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` (optional but recommended)
  - Get one at: https://cloud.walletconnect.com/
  
- `NEXT_PUBLIC_MAINNET_RPC_URL` (optional)
  - Your own RPC endpoint if you have one
  - Falls back to public RPC if not set

## Build Warnings

The React 19 peer dependency warnings are safe to ignore - they're just warnings from some dependencies that haven't updated yet.

The MetaMask SDK warning about `@react-native-async-storage/async-storage` is also safe to ignore - it's a browser-only app.
