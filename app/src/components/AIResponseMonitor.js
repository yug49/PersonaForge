import React, { useState } from "react";
import { useAccount, useWatchContractEvent } from "wagmi";
import { AGENT_MANAGER_ABI, CONTRACT_ADDRESSES } from "../config/contracts";
import {
  ClockIcon,
  CheckCircleIcon,
  CpuChipIcon,
  ExclamationTriangleIcon,
} from "@heroicons/react/24/outline";

const AIResponseMonitor = () => {
  const { address } = useAccount();
  const [requests, setRequests] = useState([]);

  // Watch for AI request events
  useWatchContractEvent({
    address: CONTRACT_ADDRESSES.AGENT_MANAGER,
    abi: AGENT_MANAGER_ABI,
    eventName: "AIRequestCreated",
    onLogs(logs) {
      logs.forEach((log) => {
        const { requestId, tokenId, requester, query, timestamp } = log.args;
        if (requester?.toLowerCase() === address?.toLowerCase()) {
          const newRequest = {
            requestId: requestId.toString(),
            tokenId: tokenId.toString(),
            query,
            timestamp: new Date(Number(timestamp) * 1000),
            status: "pending",
            response: null,
          };

          setRequests((prev) => {
            // Add new request if not already exists
            const exists = prev.some(
              (r) => r.requestId === newRequest.requestId
            );
            if (!exists) {
              return [newRequest, ...prev].slice(0, 20); // Keep only latest 20
            }
            return prev;
          });
        }
      });
    },
    enabled: !!address && !!CONTRACT_ADDRESSES.AGENT_MANAGER,
  });

  // Watch for AI response events
  useWatchContractEvent({
    address: CONTRACT_ADDRESSES.AGENT_MANAGER,
    abi: AGENT_MANAGER_ABI,
    eventName: "AIResponseSubmitted",
    onLogs(logs) {
      logs.forEach((log) => {
        const { requestId, response, timestamp } = log.args;
        const requestIdStr = requestId.toString();

        setRequests((prev) =>
          prev.map((req) =>
            req.requestId === requestIdStr
              ? {
                  ...req,
                  status: "completed",
                  response,
                  responseTimestamp: new Date(Number(timestamp) * 1000),
                }
              : req
          )
        );
      });
    },
    enabled: !!address && !!CONTRACT_ADDRESSES.AGENT_MANAGER,
  });

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
                Track your AI requests and responses in real-time
              </p>
            </div>
            <CpuChipIcon className="h-8 w-8 text-primary-500" />
          </div>
        </div>

        {/* Requests List */}
        <div className="p-6">
          {requests.length === 0 ? (
            <div className="text-center py-8">
              <ClockIcon className="mx-auto h-12 w-12 text-gray-400 mb-4" />
              <p className="text-gray-500">No AI requests found</p>
              <p className="text-sm text-gray-400 mt-2">
                Submit an AI query to see requests appear here
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {requests.map((request) => (
                <RequestCard key={request.requestId} request={request} />
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Instructions */}
      <div className="mt-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
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
                <li>
                  An off-chain server listens for these events and processes
                  them
                </li>
                <li>
                  The server fetches encrypted data from 0G Storage and decrypts
                  it
                </li>
                <li>Your query is sent to 0G Compute for AI inference</li>
                <li>The response is submitted back to the blockchain</li>
                <li>You'll see the response appear here automatically</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const RequestCard = ({ request }) => {
  const isPending = request.status === "pending";
  const isCompleted = request.status === "completed";

  return (
    <div className="border border-gray-200 rounded-lg p-4">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center space-x-2">
          <span className="text-sm font-medium text-gray-900">
            Request #{request.requestId}
          </span>
          <span className="text-xs text-gray-500">
            Token #{request.tokenId}
          </span>
        </div>

        <div className="flex items-center space-x-2">
          {isPending ? (
            <div className="flex items-center space-x-1 text-yellow-600">
              <ClockIcon className="h-4 w-4" />
              <span className="text-xs">Processing...</span>
            </div>
          ) : (
            <div className="flex items-center space-x-1 text-green-600">
              <CheckCircleIcon className="h-4 w-4" />
              <span className="text-xs">Completed</span>
            </div>
          )}

          <span className="text-xs text-gray-500">
            {request.timestamp.toLocaleTimeString()}
          </span>
        </div>
      </div>

      <div className="space-y-3">
        {/* Query */}
        <div>
          <p className="text-xs font-medium text-gray-700 mb-1">Query:</p>
          <p className="text-sm text-gray-900 bg-gray-50 rounded p-2">
            {request.query}
          </p>
        </div>

        {/* Response */}
        {isCompleted && request.response ? (
          <div>
            <p className="text-xs font-medium text-gray-700 mb-1">
              AI Response:
            </p>
            <p className="text-sm text-gray-900 bg-green-50 rounded p-2">
              {request.response}
            </p>
            {request.responseTimestamp && (
              <p className="text-xs text-gray-500 mt-1">
                Responded at: {request.responseTimestamp.toLocaleString()}
              </p>
            )}
          </div>
        ) : isPending ? (
          <div className="bg-yellow-50 border border-yellow-200 rounded p-3">
            <div className="flex items-center space-x-2">
              <div className="loading-spinner"></div>
              <span className="text-sm text-yellow-800">
                Waiting for 0G Compute to process your request...
              </span>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
};

export default AIResponseMonitor;
