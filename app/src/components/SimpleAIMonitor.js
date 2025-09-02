import React from "react";
import { useAccount } from "wagmi";
import {
  ClockIcon,
  CpuChipIcon,
  ExclamationTriangleIcon,
} from "@heroicons/react/24/outline";

const SimpleAIMonitor = () => {
  const { address } = useAccount();

  if (!address) {
    return (
      <div className="text-center py-12">
        <ExclamationTriangleIcon className="mx-auto h-16 w-16 text-gray-400 mb-4" />
        <h3 className="text-lg font-semibold text-gray-900 mb-2">
          Wallet Not Connected
        </h3>
        <p className="text-gray-600">
          Please connect your wallet to monitor AI responses.
        </p>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        {/* Header */}
        <div className="bg-gray-50 px-6 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-xl font-bold text-gray-900">
                AI Response Monitor
              </h2>
              <p className="text-sm text-gray-600">
                Track your AI requests and responses (Coming Soon)
              </p>
            </div>
            <CpuChipIcon className="h-8 w-8 text-primary-500" />
          </div>
        </div>

        {/* Placeholder Content */}
        <div className="p-6">
          <div className="text-center py-8">
            <ClockIcon className="mx-auto h-12 w-12 text-gray-400 mb-4" />
            <p className="text-gray-500">AI Response Monitoring</p>
            <p className="text-sm text-gray-400 mt-2">
              This feature will be available when the off-chain server is
              implemented
            </p>
          </div>

          {/* Demo Request Card */}
          <div className="border border-gray-200 rounded-lg p-4 bg-gray-50">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center space-x-2">
                <span className="text-sm font-medium text-gray-900">
                  Example Request #123
                </span>
                <span className="text-xs text-gray-500">Token #1</span>
              </div>

              <div className="flex items-center space-x-2">
                <div className="flex items-center space-x-1 text-yellow-600">
                  <ClockIcon className="h-4 w-4" />
                  <span className="text-xs">Pending...</span>
                </div>
                <span className="text-xs text-gray-500">2:30 PM</span>
              </div>
            </div>

            <div className="space-y-3">
              <div>
                <p className="text-xs font-medium text-gray-700 mb-1">Query:</p>
                <p className="text-sm text-gray-600 bg-white rounded p-2">
                  "What's the best approach for treating hypertension in elderly
                  patients?"
                </p>
              </div>

              <div className="bg-yellow-50 border border-yellow-200 rounded p-3">
                <div className="flex items-center space-x-2">
                  <div className="loading-spinner"></div>
                  <span className="text-sm text-yellow-800">
                    Waiting for off-chain server to process request via 0G
                    Compute...
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Instructions */}
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <div className="flex">
          <div className="flex-shrink-0">
            <svg
              className="h-5 w-5 text-blue-400"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fillRule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                clipRule="evenodd"
              />
            </svg>
          </div>
          <div className="ml-3">
            <h3 className="text-sm font-medium text-blue-800">
              How AI Processing Works
            </h3>
            <div className="mt-2 text-sm text-blue-700">
              <ul className="list-disc list-inside space-y-1">
                <li>
                  When you submit an AI query, a request is created on-chain
                </li>
                <li>The smart contract emits an AIRequestCreated event</li>
                <li>An off-chain server will listen for these events</li>
                <li>
                  The server fetches encrypted data from 0G Storage and decrypts
                  it
                </li>
                <li>Your query is sent to 0G Compute for AI inference</li>
                <li>The response is submitted back to the blockchain</li>
                <li>
                  This monitor will show real-time status when implemented
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SimpleAIMonitor;
