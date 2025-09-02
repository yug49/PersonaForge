import React, { useState, useEffect } from "react";
import { useReadContract, useAccount } from "wagmi";
import { PERSONA_INFT_ABI, CONTRACT_ADDRESSES } from "../config/contracts";
import {
  CpuChipIcon,
  ClockIcon,
  ChatBubbleLeftRightIcon,
  ArrowTopRightOnSquareIcon,
} from "@heroicons/react/24/outline";

const MyINFTs = () => {
  const { address } = useAccount();
  const [tokenDetails, setTokenDetails] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch user's tokens
  const { data: tokenIds, isLoading: tokensLoading } = useReadContract({
    address: CONTRACT_ADDRESSES.PERSONA_INFT,
    abi: PERSONA_INFT_ABI,
    functionName: "getUserTokens",
    args: [address],
    enabled: !!address && !!CONTRACT_ADDRESSES.PERSONA_INFT,
  });

  // Fetch details for each token
  useEffect(() => {
    const fetchTokenDetails = async () => {
      if (!tokenIds || tokenIds.length === 0) {
        setTokenDetails([]);
        setIsLoading(false);
        return;
      }

      setIsLoading(true);
      // In a real implementation, you would fetch token details here
      // For now, we'll create mock data
      const mockDetails = tokenIds.map((tokenId, index) => ({
        tokenId: Number(tokenId),
        groupId: index + 1,
        personalityTraits: `Personality traits for token ${tokenId}`,
        mintedAt: Date.now() - index * 86400000, // Different days
        lastInteraction: index === 0 ? Date.now() - 3600000 : 0, // Last hour for first token
        isActive: true,
        groupName: `Persona Group ${index + 1}`,
        groupDescription: `Description for persona group ${index + 1}`,
      }));

      setTokenDetails(mockDetails);
      setIsLoading(false);
    };

    fetchTokenDetails();
  }, [tokenIds]);

  if (tokensLoading || isLoading) {
    return (
      <div className="text-center py-8">
        <div className="loading-spinner mx-auto mb-4"></div>
        <p className="text-gray-500">Loading your PersonaINFTs...</p>
      </div>
    );
  }

  if (!tokenDetails.length) {
    return (
      <div className="text-center py-8">
        <CpuChipIcon className="mx-auto h-12 w-12 text-gray-400 mb-4" />
        <h3 className="text-lg font-medium text-gray-900 mb-2">
          No PersonaINFTs
        </h3>
        <p className="text-gray-500 mb-4">
          You don't own any PersonaINFTs yet.
        </p>
        <button className="btn-primary text-sm">Mint Your First INFT</button>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {tokenDetails.map((token) => (
        <INFTCard key={token.tokenId} token={token} />
      ))}
    </div>
  );
};

const INFTCard = ({ token }) => {
  const formatDate = (timestamp) => {
    return new Date(timestamp).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  };

  const formatTimeAgo = (timestamp) => {
    if (!timestamp) return "Never";
    const now = Date.now();
    const diff = now - timestamp;
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    return "Recently";
  };

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6 card-hover">
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center space-x-3">
          <div className="w-12 h-12 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-lg flex items-center justify-center">
            <CpuChipIcon className="h-6 w-6 text-white" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900">
              INFT #{token.tokenId}
            </h3>
            <p className="text-sm text-gray-500">Group #{token.groupId}</p>
          </div>
        </div>
        <div
          className={`px-2 py-1 rounded-full text-xs font-medium ${
            token.isActive
              ? "bg-green-100 text-green-800"
              : "bg-red-100 text-red-800"
          }`}
        >
          {token.isActive ? "Active" : "Inactive"}
        </div>
      </div>

      {/* Group Info */}
      <div className="mb-4">
        <h4 className="font-medium text-gray-900 mb-1">{token.groupName}</h4>
        <p className="text-sm text-gray-600 line-clamp-2">
          {token.groupDescription}
        </p>
      </div>

      {/* Personality Traits */}
      <div className="mb-4">
        <p className="text-sm text-gray-700">
          <span className="font-medium">Traits:</span> {token.personalityTraits}
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4 mb-4 text-sm">
        <div className="flex items-center space-x-2 text-gray-600">
          <ClockIcon className="h-4 w-4" />
          <div>
            <p className="font-medium">Minted</p>
            <p>{formatDate(token.mintedAt)}</p>
          </div>
        </div>
        <div className="flex items-center space-x-2 text-gray-600">
          <ChatBubbleLeftRightIcon className="h-4 w-4" />
          <div>
            <p className="font-medium">Last Chat</p>
            <p>{formatTimeAgo(token.lastInteraction)}</p>
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="flex space-x-2">
        <button className="flex-1 btn-primary text-sm flex items-center justify-center space-x-1">
          <ChatBubbleLeftRightIcon className="h-4 w-4" />
          <span>Chat</span>
        </button>
        <button className="btn-outline text-sm flex items-center justify-center">
          <ArrowTopRightOnSquareIcon className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
};

export default MyINFTs;
