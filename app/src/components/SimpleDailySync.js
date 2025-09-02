import React, { useState, useEffect } from "react";
import {
  useWriteContract,
  useWaitForTransactionReceipt,
  useAccount,
} from "wagmi";
import { toast } from "react-hot-toast";
import { STORAGE_MANAGER_ABI, CONTRACT_ADDRESSES } from "../config/contracts";
import {
  BookOpenIcon,
  PlusIcon,
  CalendarDaysIcon,
} from "@heroicons/react/24/outline";

const SimpleDailySync = () => {
  const { address } = useAccount();
  const [selectedGroupId, setSelectedGroupId] = useState("1");
  const [dailyThoughts, setDailyThoughts] = useState("");
  const [entryType, setEntryType] = useState("daily_sync");
  const [isLoading, setIsLoading] = useState(false);

  const { writeContract, data: hash } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const handleDailySync = async (e) => {
    e.preventDefault();

    if (!dailyThoughts.trim()) {
      toast.error("Please enter your daily thoughts");
      return;
    }

    if (!selectedGroupId) {
      toast.error("Please enter a group ID");
      return;
    }

    if (!CONTRACT_ADDRESSES.STORAGE_MANAGER) {
      toast.error("Storage Manager contract address not configured");
      return;
    }

    setIsLoading(true);

    try {
      await writeContract({
        address: CONTRACT_ADDRESSES.STORAGE_MANAGER,
        abi: STORAGE_MANAGER_ABI,
        functionName: "dailySync",
        args: [parseInt(selectedGroupId), dailyThoughts],
      });
    } catch (error) {
      console.error("Error adding daily sync:", error);
      toast.error(error.message || "Failed to add daily sync");
      setIsLoading(false);
    }
  };

  const handleCustomEntry = async (e) => {
    e.preventDefault();

    if (!dailyThoughts.trim()) {
      toast.error("Please enter your entry content");
      return;
    }

    if (!selectedGroupId) {
      toast.error("Please enter a group ID");
      return;
    }

    if (!CONTRACT_ADDRESSES.STORAGE_MANAGER) {
      toast.error("Storage Manager contract address not configured");
      return;
    }

    setIsLoading(true);

    try {
      await writeContract({
        address: CONTRACT_ADDRESSES.STORAGE_MANAGER,
        abi: STORAGE_MANAGER_ABI,
        functionName: "addJournalEntry",
        args: [parseInt(selectedGroupId), dailyThoughts, entryType],
      });
    } catch (error) {
      console.error("Error adding journal entry:", error);
      toast.error(error.message || "Failed to add journal entry");
      setIsLoading(false);
    }
  };

  // Handle transaction success
  useEffect(() => {
    if (isSuccess) {
      setIsLoading(false);
      setDailyThoughts("");
      toast.success("Entry added successfully!");
    }
  }, [isSuccess]);

  const isSubmitting = isLoading || isConfirming;

  if (!address) {
    return (
      <div className="text-center py-12">
        <BookOpenIcon className="mx-auto h-16 w-16 text-gray-400 mb-4" />
        <h3 className="text-lg font-semibold text-gray-900 mb-2">
          Wallet Not Connected
        </h3>
        <p className="text-gray-600">
          Please connect your wallet to manage your daily sync.
        </p>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-xl font-bold text-gray-900">Daily Sync</h2>
            <p className="text-sm text-gray-600">
              Add daily thoughts and experiences to enhance your AI personas
            </p>
          </div>
          <CalendarDaysIcon className="h-8 w-8 text-primary-500" />
        </div>

        {/* Group Selector */}
        <div className="mb-6">
          <label
            htmlFor="groupSelect"
            className="block text-sm font-medium text-gray-700 mb-2"
          >
            Storage Group ID:
          </label>
          <input
            type="number"
            id="groupSelect"
            value={selectedGroupId}
            onChange={(e) => setSelectedGroupId(e.target.value)}
            placeholder="Enter group ID (e.g., 1)"
            className="form-input max-w-xs"
          />
          <p className="text-xs text-gray-500 mt-1">
            Enter the storage group ID you have access to update
          </p>
        </div>

        {/* Entry Form */}
        <div className="space-y-4">
          {/* Entry Type Selector */}
          <div>
            <label
              htmlFor="entryType"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Entry Type:
            </label>
            <select
              id="entryType"
              value={entryType}
              onChange={(e) => setEntryType(e.target.value)}
              className="form-input max-w-xs"
            >
              <option value="daily_sync">Daily Sync</option>
              <option value="experience">Experience</option>
              <option value="thought">Thought</option>
              <option value="memory">Memory</option>
              <option value="insight">Insight</option>
              <option value="learning">Learning</option>
            </select>
          </div>

          {/* Entry Content */}
          <div>
            <label
              htmlFor="dailyThoughts"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              {entryType === "daily_sync"
                ? "Daily Thoughts:"
                : "Entry Content:"}
            </label>
            <textarea
              id="dailyThoughts"
              value={dailyThoughts}
              onChange={(e) => setDailyThoughts(e.target.value)}
              placeholder={
                entryType === "daily_sync"
                  ? "Share your daily experiences, thoughts, and learnings..."
                  : "Enter your journal entry content..."
              }
              className="form-input min-h-[120px]"
              disabled={isSubmitting}
            />
          </div>

          {/* Submit Buttons */}
          <div className="flex space-x-4">
            <button
              onClick={handleDailySync}
              disabled={
                isSubmitting || !dailyThoughts.trim() || !selectedGroupId
              }
              className="btn-primary flex items-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? (
                <div className="loading-spinner"></div>
              ) : (
                <CalendarDaysIcon className="h-4 w-4" />
              )}
              <span>{isSubmitting ? "Adding..." : "Quick Daily Sync"}</span>
            </button>

            <button
              onClick={handleCustomEntry}
              disabled={
                isSubmitting || !dailyThoughts.trim() || !selectedGroupId
              }
              className="btn-secondary flex items-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? (
                <div className="loading-spinner"></div>
              ) : (
                <PlusIcon className="h-4 w-4" />
              )}
              <span>{isSubmitting ? "Adding..." : `Add ${entryType}`}</span>
            </button>
          </div>
        </div>

        {/* Transaction Hash */}
        {hash && (
          <div className="mt-4 p-3 bg-gray-50 rounded-lg border">
            <p className="text-xs text-gray-600">Transaction Hash:</p>
            <p className="font-mono text-xs text-gray-800 break-all">{hash}</p>
          </div>
        )}
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
              How Daily Sync Works
            </h3>
            <div className="mt-2 text-sm text-blue-700">
              <ul className="list-disc list-inside space-y-1">
                <li>Enter a storage group ID that you have access to update</li>
                <li>Share your daily experiences, thoughts, and learnings</li>
                <li>
                  Choose the appropriate entry type for better organization
                </li>
                <li>All entries are encrypted and stored on 0G Storage</li>
                <li>
                  Your AI personas can access this data to provide better
                  responses
                </li>
                <li>
                  Entries are append-only and create a permanent knowledge base
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SimpleDailySync;
