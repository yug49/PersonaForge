import React from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount } from "wagmi";

const Header = () => {
  const { isConnected } = useAccount();

  return (
    <header className="bg-white shadow-sm border-b border-gray-200">
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2">
              <div className="w-8 h-8 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-sm">PF</span>
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900">
                  PersonaForge
                </h1>
                <p className="text-xs text-gray-500">Intelligent NFTs</p>
              </div>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            {isConnected && (
              <div className="hidden md:flex items-center space-x-2 text-sm text-gray-600">
                <div className="w-2 h-2 bg-green-400 rounded-full"></div>
                <span>0G Testnet</span>
              </div>
            )}
            <ConnectButton />
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;
