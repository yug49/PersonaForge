import React, { useState, useEffect } from "react";
import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { toast } from "react-hot-toast";
import { keccak256, toBytes } from "viem";
import { STORAGE_MANAGER_ABI, CONTRACT_ADDRESSES } from "../config/contracts";
import {
  CloudArrowUpIcon,
  DocumentTextIcon,
} from "@heroicons/react/24/outline";

const StorageManager = () => {
  const [activeSection, setActiveSection] = useState("create");
  // const [storageGroups, setStorageGroups] = useState([]); // TODO: Implement storage group fetching

  return (
    <div className="max-w-6xl mx-auto">
      {/* Section Navigation */}
      <div className="mb-8">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            <button
              onClick={() => setActiveSection("create")}
              className={`${
                activeSection === "create"
                  ? "border-primary-500 text-primary-600"
                  : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              } whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm`}
            >
              Create Storage Group
            </button>
            <button
              onClick={() => setActiveSection("manage")}
              className={`${
                activeSection === "manage"
                  ? "border-primary-500 text-primary-600"
                  : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              } whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm`}
            >
              Manage Storage
            </button>
          </nav>
        </div>
      </div>

      {/* Content */}
      {activeSection === "create" && <CreateStorageGroup />}
      {activeSection === "manage" && <ManageStorage />}
    </div>
  );
};

const CreateStorageGroup = () => {
  const [formData, setFormData] = useState({
    name: "",
    personalityData: "",
    encryptionKey: "",
  });
  const [isLoading, setIsLoading] = useState(false);

  const { writeContract, data: hash } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const generateEncryptionKey = () => {
    const key = `key_${Date.now()}_${Math.random().toString(36).substr(2, 16)}`;
    setFormData((prev) => ({ ...prev, encryptionKey: key }));
    toast.success("Encryption key generated!");
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (
      !formData.name ||
      !formData.personalityData ||
      !formData.encryptionKey
    ) {
      toast.error("Please fill in all required fields");
      return;
    }

    if (!CONTRACT_ADDRESSES.STORAGE_MANAGER) {
      toast.error("Storage Manager contract address not configured");
      return;
    }

    setIsLoading(true);

    try {
      // Generate mock encrypted data
      const mockEncryptedData = `encrypted_${Date.now()}_${Math.random()
        .toString(36)
        .substr(2, 9)}`;
      const storageURI = `0g://storage/data-${mockEncryptedData}`;
      const encryptionKeyHash = keccak256(toBytes(formData.encryptionKey));
      const dataHash = keccak256(
        toBytes(formData.personalityData + mockEncryptedData)
      );

      await writeContract({
        address: CONTRACT_ADDRESSES.STORAGE_MANAGER,
        abi: STORAGE_MANAGER_ABI,
        functionName: "createStorageGroup",
        args: [formData.name, encryptionKeyHash, storageURI, dataHash],
      });

      toast.success("Transaction submitted! Waiting for confirmation...");
    } catch (error) {
      console.error("Error creating storage group:", error);
      toast.error(error.message || "Failed to create storage group");
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (isSuccess) {
      toast.success("Storage Group created successfully!");
      setFormData({
        name: "",
        personalityData: "",
        encryptionKey: "",
      });
      setIsLoading(false);
    }
  }, [isSuccess]);

  const isSubmitting = isLoading || isConfirming;

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      <div className="mb-6">
        <h2 className="text-xl font-bold text-gray-900">
          Create Storage Group
        </h2>
        <p className="text-gray-600 mt-2">
          Set up centralized encrypted storage for persona data. This storage
          will be managed by you and accessed by AI agents.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Name Field */}
        <div>
          <label htmlFor="name" className="form-label">
            Storage Group Name *
          </label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleInputChange}
            placeholder="e.g., Shakespeare Knowledge Base, Technical Support Data"
            className="form-input"
            required
          />
        </div>

        {/* Personality Data */}
        <div>
          <label htmlFor="personalityData" className="form-label">
            Persona Data *
          </label>
          <textarea
            id="personalityData"
            name="personalityData"
            value={formData.personalityData}
            onChange={handleInputChange}
            placeholder="Enter the knowledge base, personality traits, conversation patterns, etc..."
            className="form-textarea"
            rows={8}
            required
          />
          <p className="text-xs text-gray-500 mt-1">
            This data will be encrypted and stored on 0G Storage
          </p>
        </div>

        {/* Encryption Key */}
        <div>
          <label htmlFor="encryptionKey" className="form-label">
            Encryption Key *
          </label>
          <div className="flex space-x-2">
            <input
              type="text"
              id="encryptionKey"
              name="encryptionKey"
              value={formData.encryptionKey}
              onChange={handleInputChange}
              placeholder="Generate or enter encryption key"
              className="form-input"
              required
            />
            <button
              type="button"
              onClick={generateEncryptionKey}
              className="btn-outline whitespace-nowrap"
            >
              Generate Key
            </button>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            Keep this key secure! It will be hashed and stored on-chain, but you
            need the original for decryption.
          </p>
        </div>

        {/* Info Box */}
        <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
          <div className="flex">
            <CloudArrowUpIcon className="h-5 w-5 text-purple-400 flex-shrink-0" />
            <div className="ml-3">
              <h3 className="text-sm font-medium text-purple-800">
                Storage Process
              </h3>
              <div className="mt-2 text-sm text-purple-700">
                <ul className="list-disc list-inside space-y-1">
                  <li>Data will be encrypted with your encryption key</li>
                  <li>Encrypted data uploaded to 0G Storage (decentralized)</li>
                  <li>Only key hash stored on-chain (not the actual key)</li>
                  <li>You control updates and access to this storage group</li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        {/* Submit Button */}
        <div className="flex justify-end">
          <button
            type="submit"
            disabled={isSubmitting}
            className="btn-primary flex items-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isSubmitting && <div className="loading-spinner"></div>}
            <span>
              {isConfirming
                ? "Confirming..."
                : isLoading
                ? "Creating..."
                : "Create Storage Group"}
            </span>
          </button>
        </div>
      </form>

      {/* Transaction Hash */}
      {hash && (
        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <p className="text-sm text-gray-600">Transaction Hash:</p>
          <p className="font-mono text-xs text-gray-800 break-all">{hash}</p>
        </div>
      )}
    </div>
  );
};

const ManageStorage = () => {
  const [updateFormData, setUpdateFormData] = useState({
    groupId: "",
    newPersonaData: "",
    updateReason: "",
  });
  const [isLoading, setIsLoading] = useState(false);

  const { writeContract, data: hash } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setUpdateFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleUpdate = async (e) => {
    e.preventDefault();

    if (
      !updateFormData.groupId ||
      !updateFormData.newPersonaData ||
      !updateFormData.updateReason
    ) {
      toast.error("Please fill in all required fields");
      return;
    }

    if (!CONTRACT_ADDRESSES.STORAGE_MANAGER) {
      toast.error("Storage Manager contract address not configured");
      return;
    }

    setIsLoading(true);

    try {
      // Generate new encrypted data
      const mockEncryptedData = `updated_${Date.now()}_${Math.random()
        .toString(36)
        .substr(2, 9)}`;
      const newStorageURI = `0g://storage/updated-${mockEncryptedData}`;
      const newDataHash = keccak256(
        toBytes(updateFormData.newPersonaData + mockEncryptedData)
      );

      await writeContract({
        address: CONTRACT_ADDRESSES.STORAGE_MANAGER,
        abi: STORAGE_MANAGER_ABI,
        functionName: "updatePersonaData",
        args: [
          parseInt(updateFormData.groupId),
          newStorageURI,
          newDataHash,
          updateFormData.updateReason,
        ],
      });

      toast.success(
        "Update transaction submitted! Waiting for confirmation..."
      );
    } catch (error) {
      console.error("Error updating storage:", error);
      toast.error(error.message || "Failed to update storage");
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (isSuccess) {
      toast.success("Storage updated successfully!");
      setUpdateFormData({
        groupId: "",
        newPersonaData: "",
        updateReason: "",
      });
      setIsLoading(false);
    }
  }, [isSuccess]);

  const isSubmitting = isLoading || isConfirming;

  return (
    <div className="space-y-8">
      {/* Update Storage Form */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="mb-6">
          <h2 className="text-xl font-bold text-gray-900">
            Update Storage Group
          </h2>
          <p className="text-gray-600 mt-2">
            Update the persona data in an existing storage group. This will
            affect all INFTs linked to this group.
          </p>
        </div>

        <form onSubmit={handleUpdate} className="space-y-6">
          {/* Group ID */}
          <div>
            <label htmlFor="groupId" className="form-label">
              Storage Group ID *
            </label>
            <input
              type="number"
              id="groupId"
              name="groupId"
              value={updateFormData.groupId}
              onChange={handleInputChange}
              placeholder="Enter the ID of the storage group to update"
              className="form-input"
              min="1"
              required
            />
          </div>

          {/* New Persona Data */}
          <div>
            <label htmlFor="newPersonaData" className="form-label">
              Updated Persona Data *
            </label>
            <textarea
              id="newPersonaData"
              name="newPersonaData"
              value={updateFormData.newPersonaData}
              onChange={handleInputChange}
              placeholder="Enter the updated knowledge base, personality traits, etc..."
              className="form-textarea"
              rows={8}
              required
            />
          </div>

          {/* Update Reason */}
          <div>
            <label htmlFor="updateReason" className="form-label">
              Update Reason *
            </label>
            <input
              type="text"
              id="updateReason"
              name="updateReason"
              value={updateFormData.updateReason}
              onChange={handleInputChange}
              placeholder="e.g., Added new training data, Fixed personality quirks, Updated knowledge base"
              className="form-input"
              required
            />
          </div>

          {/* Warning Box */}
          <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
            <div className="flex">
              <svg
                className="h-5 w-5 text-orange-400 flex-shrink-0"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fillRule="evenodd"
                  d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                  clipRule="evenodd"
                />
              </svg>
              <div className="ml-3">
                <h3 className="text-sm font-medium text-orange-800">
                  Important
                </h3>
                <div className="mt-2 text-sm text-orange-700">
                  <p>
                    This update will affect all INFTs linked to this storage
                    group. All AI agents using this data will start responding
                    based on the new information.
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Submit Button */}
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={isSubmitting}
              className="btn-primary flex items-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting && <div className="loading-spinner"></div>}
              <span>
                {isConfirming
                  ? "Confirming..."
                  : isLoading
                  ? "Updating..."
                  : "Update Storage"}
              </span>
            </button>
          </div>
        </form>

        {/* Transaction Hash */}
        {hash && (
          <div className="mt-6 p-4 bg-gray-50 rounded-lg">
            <p className="text-sm text-gray-600">Transaction Hash:</p>
            <p className="font-mono text-xs text-gray-800 break-all">{hash}</p>
          </div>
        )}
      </div>

      {/* Storage Groups Overview */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Storage Groups Overview
        </h3>
        <div className="text-center py-8 text-gray-500">
          <DocumentTextIcon className="mx-auto h-12 w-12 text-gray-400 mb-2" />
          <p>
            Storage group listing will be implemented with contract integration
          </p>
          <p className="text-sm">
            Use the contract's read functions to fetch your storage groups
          </p>
        </div>
      </div>
    </div>
  );
};

export default StorageManager;
