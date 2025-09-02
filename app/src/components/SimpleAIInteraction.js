import React, { useState, useEffect } from "react";
import {
  useWriteContract,
  useWaitForTransactionReceipt,
  useReadContract,
  useAccount,
} from "wagmi";
import { toast } from "react-hot-toast";
import { PERSONA_INFT_ABI, CONTRACT_ADDRESSES } from "../config/contracts";
import {
  ChatBubbleLeftRightIcon,
  PaperAirplaneIcon,
  UserIcon,
  CpuChipIcon,
  ExclamationTriangleIcon,
} from "@heroicons/react/24/outline";

const SimpleAIInteraction = () => {
  const { address } = useAccount();
  const [selectedTokenId, setSelectedTokenId] = useState("");
  const [query, setQuery] = useState("");
  const [chatHistory, setChatHistory] = useState([]);
  const [userTokens, setUserTokens] = useState([]);
  const [isLoading, setIsLoading] = useState(false);

  const { writeContract, data: hash } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  // Fetch user's tokens
  const { data: tokenIds } = useReadContract({
    address: CONTRACT_ADDRESSES.PERSONA_INFT,
    abi: PERSONA_INFT_ABI,
    functionName: "getUserTokens",
    args: [address],
    enabled: !!address && !!CONTRACT_ADDRESSES.PERSONA_INFT,
  });

  useEffect(() => {
    if (tokenIds && tokenIds.length > 0) {
      setUserTokens(tokenIds.map((id) => Number(id)));
      if (!selectedTokenId && tokenIds.length > 0) {
        setSelectedTokenId(tokenIds[0].toString());
      }
    }
  }, [tokenIds, selectedTokenId]);

  const handleSendMessage = async (e) => {
    e.preventDefault();

    if (!query.trim()) {
      toast.error("Please enter a message");
      return;
    }

    if (!selectedTokenId) {
      toast.error("Please select a PersonaINFT");
      return;
    }

    if (!CONTRACT_ADDRESSES.PERSONA_INFT) {
      toast.error("PersonaINFT contract address not configured");
      return;
    }

    // Add user message to chat history
    const userMessage = {
      id: Date.now(),
      type: "user",
      content: query,
      timestamp: new Date(),
    };
    setChatHistory((prev) => [...prev, userMessage]);

    setIsLoading(true);
    const currentQuery = query;
    setQuery(""); // Clear input immediately

    try {
      await writeContract({
        address: CONTRACT_ADDRESSES.PERSONA_INFT,
        abi: PERSONA_INFT_ABI,
        functionName: "interactWithAgent",
        args: [parseInt(selectedTokenId), currentQuery],
      });

      // Add loading message to chat
      const loadingMessage = {
        id: Date.now() + 1,
        type: "agent",
        content:
          "AI request submitted to 0G network. Response will be processed off-chain...",
        timestamp: new Date(),
        isLoading: true,
      };
      setChatHistory((prev) => [...prev, loadingMessage]);
    } catch (error) {
      console.error("Error interacting with agent:", error);
      toast.error(error.message || "Failed to send message");
      setIsLoading(false);

      // Remove user message on error
      setChatHistory((prev) => prev.filter((msg) => msg.id !== userMessage.id));
    }
  };

  // Handle transaction success
  useEffect(() => {
    if (isSuccess) {
      setIsLoading(false);
      toast.success("AI request submitted successfully!");

      // Replace loading message with explanation
      const explanationMessage = {
        id: Date.now() + 2,
        type: "agent",
        content:
          "✅ Your AI request has been submitted to the blockchain! In production, an off-chain server would process this request using 0G Compute and submit the response back to the contract. You can monitor the request status in the 'AI Monitor' tab.",
        timestamp: new Date(),
        isLoading: false,
        isExplanation: true,
      };

      setChatHistory((prev) =>
        prev.map((msg) => (msg.isLoading ? explanationMessage : msg))
      );
    }
  }, [isSuccess, selectedTokenId]);

  const handleTokenSelect = (tokenId) => {
    setSelectedTokenId(tokenId);
    setChatHistory([]); // Clear chat history when switching tokens
  };

  const isSubmitting = isLoading || isConfirming;

  if (!address) {
    return (
      <div className="text-center py-12">
        <ExclamationTriangleIcon className="mx-auto h-16 w-16 text-gray-400 mb-4" />
        <h3 className="text-lg font-semibold text-gray-900 mb-2">
          Wallet Not Connected
        </h3>
        <p className="text-gray-600">
          Please connect your wallet to interact with AI agents.
        </p>
      </div>
    );
  }

  if (!userTokens.length) {
    return (
      <div className="text-center py-12">
        <CpuChipIcon className="mx-auto h-16 w-16 text-gray-400 mb-4" />
        <h3 className="text-lg font-semibold text-gray-900 mb-2">
          No PersonaINFTs Found
        </h3>
        <p className="text-gray-600 mb-4">
          You don't own any PersonaINFTs yet. Mint one to start interacting with
          AI agents.
        </p>
        <button className="btn-primary">Go to Mint INFT</button>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        {/* Header */}
        <div className="bg-gray-50 px-6 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-xl font-bold text-gray-900">AI Agent Chat</h2>
              <p className="text-sm text-gray-600">
                Submit AI requests to your PersonaINFT agents
              </p>
            </div>

            {/* Token Selector */}
            <div className="flex items-center space-x-2">
              <label
                htmlFor="tokenSelect"
                className="text-sm font-medium text-gray-700"
              >
                Select INFT:
              </label>
              <select
                id="tokenSelect"
                value={selectedTokenId}
                onChange={(e) => handleTokenSelect(e.target.value)}
                className="form-input min-w-[120px]"
              >
                {userTokens.map((tokenId) => (
                  <option key={tokenId} value={tokenId}>
                    INFT #{tokenId}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* Chat Area */}
        <div className="h-96 overflow-y-auto p-6 space-y-4">
          {chatHistory.length === 0 ? (
            <div className="text-center py-8">
              <ChatBubbleLeftRightIcon className="mx-auto h-12 w-12 text-gray-400 mb-4" />
              <p className="text-gray-500">
                Start a conversation with your AI agent!
              </p>
              <p className="text-sm text-gray-400 mt-2">
                Your messages will be processed by the AI agent associated with
                PersonaINFT #{selectedTokenId}
              </p>
            </div>
          ) : (
            chatHistory.map((message) => (
              <ChatMessage key={message.id} message={message} />
            ))
          )}
        </div>

        {/* Input Area */}
        <div className="bg-gray-50 px-6 py-4 border-t border-gray-200">
          <form onSubmit={handleSendMessage} className="flex space-x-4">
            <div className="flex-1">
              <input
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Type your message to the AI agent..."
                className="form-input"
                disabled={isSubmitting}
              />
            </div>
            <button
              type="submit"
              disabled={isSubmitting || !query.trim()}
              className="btn-primary flex items-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? (
                <div className="loading-spinner"></div>
              ) : (
                <PaperAirplaneIcon className="h-4 w-4" />
              )}
              <span>{isSubmitting ? "Sending..." : "Send"}</span>
            </button>
          </form>

          {selectedTokenId && (
            <p className="text-xs text-gray-500 mt-2">
              Chatting with AI agent from PersonaINFT #{selectedTokenId}
            </p>
          )}
        </div>

        {/* Transaction Hash */}
        {hash && (
          <div className="px-6 py-3 bg-gray-50 border-t border-gray-200">
            <p className="text-xs text-gray-600">Transaction Hash:</p>
            <p className="font-mono text-xs text-gray-800 break-all">{hash}</p>
          </div>
        )}
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
            <h3 className="text-sm font-medium text-blue-800">How it works</h3>
            <div className="mt-2 text-sm text-blue-700">
              <ul className="list-disc list-inside space-y-1">
                <li>Select one of your PersonaINFTs from the dropdown</li>
                <li>
                  Type your message and click Send to submit an AI request
                </li>
                <li>
                  The request is recorded on the blockchain with event emission
                </li>
                <li>
                  In production, an off-chain server processes requests via 0G
                  Compute
                </li>
                <li>Use the 'AI Monitor' tab to track request status</li>
                <li>
                  Switch between different INFTs to interact with different AI
                  personalities
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const ChatMessage = ({ message }) => {
  const isUser = message.type === "user";
  const isExplanation = message.isExplanation;

  return (
    <div className={`flex ${isUser ? "justify-end" : "justify-start"}`}>
      <div
        className={`flex max-w-xs lg:max-w-md ${
          isUser ? "flex-row-reverse" : "flex-row"
        }`}
      >
        <div className={`flex-shrink-0 ${isUser ? "ml-2" : "mr-2"}`}>
          <div
            className={`w-8 h-8 rounded-full flex items-center justify-center ${
              isUser
                ? "bg-primary-500"
                : isExplanation
                ? "bg-green-500"
                : "bg-gray-500"
            }`}
          >
            {isUser ? (
              <UserIcon className="h-4 w-4 text-white" />
            ) : (
              <CpuChipIcon className="h-4 w-4 text-white" />
            )}
          </div>
        </div>
        <div
          className={`rounded-lg px-4 py-2 ${
            isUser
              ? "bg-primary-500 text-white"
              : isExplanation
              ? "bg-green-100 text-green-900 border border-green-200"
              : "bg-gray-200 text-gray-900"
          }`}
        >
          {message.isLoading ? (
            <div className="flex items-center space-x-2">
              <div className="loading-spinner"></div>
              <span>{message.content}</span>
            </div>
          ) : (
            <p className="text-sm">{message.content}</p>
          )}
          <p
            className={`text-xs mt-1 ${
              isUser
                ? "text-primary-100"
                : isExplanation
                ? "text-green-600"
                : "text-gray-500"
            }`}
          >
            {message.timestamp.toLocaleTimeString()}
          </p>
        </div>
      </div>
    </div>
  );
};

export default SimpleAIInteraction;
