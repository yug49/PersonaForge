import React from "react";
import { useAccount, useChainId } from "wagmi";
import {
  CheckCircleIcon,
  ExclamationTriangleIcon,
  GlobeAltIcon,
} from "@heroicons/react/24/outline";

const NetworkStatus = () => {
  const { isConnected } = useAccount();
  const chainId = useChainId();

  const isCorrectNetwork = chainId === 16601; // OG-Galileo-Testnet

  if (!isConnected) {
    return null; // Don't show if wallet not connected
  }

  return (
    <div
      className={`rounded-lg border p-4 ${
        isCorrectNetwork
          ? "bg-green-50 border-green-200"
          : "bg-yellow-50 border-yellow-200"
      }`}
    >
      <div className="flex items-center space-x-3">
        <div className="flex-shrink-0">
          {isCorrectNetwork ? (
            <CheckCircleIcon className="h-6 w-6 text-green-500" />
          ) : (
            <ExclamationTriangleIcon className="h-6 w-6 text-yellow-500" />
          )}
        </div>

        <div className="flex-1">
          <div className="flex items-center space-x-2">
            <GlobeAltIcon className="h-4 w-4 text-gray-500" />
            <span className="text-sm font-medium text-gray-900">
              Network Status:
            </span>
          </div>

          {isCorrectNetwork ? (
            <p className="text-sm text-green-700 mt-1">
              ✅ Connected to OG-Galileo-Testnet (Chain ID: {chainId})
            </p>
          ) : (
            <div className="mt-1">
              <p className="text-sm text-yellow-700">
                ⚠️ Wrong network detected (Chain ID: {chainId})
              </p>
              <p className="text-xs text-yellow-600 mt-1">
                Please switch to OG-Galileo-Testnet (Chain ID: 16601) in your
                wallet
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default NetworkStatus;
