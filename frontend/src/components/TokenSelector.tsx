"use client";

import { useState, useRef, useEffect } from "react";

interface Token {
  address: string;
  symbol: string;
  name: string;
  decimals: number;
}

interface TokenSelectorProps {
  selectedToken: Token | null;
  onSelect: (token: Token) => void;
  tokens: Token[];
}

export function TokenSelector({
  selectedToken,
  onSelect,
  tokens,
}: TokenSelectorProps) {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
      }
    }

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const getTokenIcon = (symbol: string) => {
    // Simple colored circles as token icons
    const colors: Record<string, string> = {
      WETH: "bg-blue-500",
      USDC: "bg-green-500",
      WBTC: "bg-orange-500",
      COMP: "bg-teal-500",
      UNI: "bg-pink-500",
      LINK: "bg-blue-400",
    };

    return (
      <div
        className={`w-6 h-6 rounded-full ${colors[symbol] || "bg-void-500"} flex items-center justify-center`}
      >
        <span className="text-xs font-bold text-white">
          {symbol.charAt(0)}
        </span>
      </div>
    );
  };

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-2 rounded-xl bg-void-800 hover:bg-void-700 border border-void-700 hover:border-comet-500/50 transition-all"
      >
        {selectedToken && getTokenIcon(selectedToken.symbol)}
        <span className="font-semibold text-void-100">
          {selectedToken?.symbol || "Select"}
        </span>
        <svg
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          className={`text-void-400 transition-transform ${isOpen ? "rotate-180" : ""}`}
        >
          <path d="M6 9l6 6 6-6" />
        </svg>
      </button>

      {/* Dropdown */}
      {isOpen && (
        <div className="absolute right-0 mt-2 w-48 glass rounded-xl overflow-hidden z-50 animate-in fade-in slide-in-from-top-2 duration-200">
          <div className="py-1">
            {tokens.map((token) => (
              <button
                key={token.address}
                onClick={() => {
                  onSelect(token);
                  setIsOpen(false);
                }}
                className={`w-full flex items-center gap-3 px-4 py-3 hover:bg-void-800/50 transition-colors ${
                  selectedToken?.address === token.address
                    ? "bg-comet-500/10"
                    : ""
                }`}
              >
                {getTokenIcon(token.symbol)}
                <div className="text-left">
                  <div className="font-medium text-void-100">{token.symbol}</div>
                  <div className="text-xs text-void-400">{token.name}</div>
                </div>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
