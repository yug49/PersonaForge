import React, { useState, useEffect } from "react";
import {
  useWriteContract,
  useWaitForTransactionReceipt,
  useAccount,
} from "wagmi";
import { toast } from "react-hot-toast";
import { PERSONA_INFT_ABI, CONTRACT_ADDRESSES } from "../config/contracts";

const MintPersonaINFT = () => {
  const { address } = useAccount();
  const [formData, setFormData] = useState({
    recipient: "",
    groupId: "",
    personalityTraits: "",
  });
  // const [availableGroups, setAvailableGroups] = useState([]); // TODO: Implement group fetching
  const [isLoading, setIsLoading] = useState(false);

  const { writeContract, data: hash } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  // Set default recipient to connected address
  useEffect(() => {
    if (address && !formData.recipient) {
      setFormData((prev) => ({ ...prev, recipient: address }));
    }
  }, [address, formData.recipient]);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (
      !formData.recipient ||
      !formData.groupId ||
      !formData.personalityTraits
    ) {
      toast.error("Please fill in all required fields");
      return;
    }

    if (!CONTRACT_ADDRESSES.PERSONA_INFT) {
      toast.error(
        "Persona Group cannout be created because the 0g storage is not configured yet, it will be done in the next waves. For now, the contracts and INFT functionalities are completed and can be reviewed at contract level or through tests."
      );
      return;
    }

    setIsLoading(true);

    try {
      await writeContract({
        address: CONTRACT_ADDRESSES.PERSONA_INFT,
        abi: PERSONA_INFT_ABI,
        functionName: "mintPersonaINFT",
        args: [
          formData.recipient,
          parseInt(formData.groupId),
          formData.personalityTraits,
        ],
      });

      toast.success("Transaction submitted! Waiting for confirmation...");
    } catch (error) {
      console.error("Error minting INFT:", error);
      toast.error(error.message || "Failed to mint PersonaINFT");
      setIsLoading(false);
    }
  };

  // Handle transaction success
  useEffect(() => {
    if (isSuccess) {
      toast.success("PersonaINFT minted successfully!");
      setFormData({
        recipient: address || "",
        groupId: "",
        personalityTraits: "",
      });
      setIsLoading(false);
    }
  }, [isSuccess, address]);

  const isSubmitting = isLoading || isConfirming;

  return (
    <div className="max-w-2xl mx-auto">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-gray-900">Mint PersonaINFT</h2>
          <p className="text-gray-600 mt-2">
            Mint a new Intelligent NFT that grants access to an AI agent. The
            NFT holder will be able to interact with the AI persona.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Recipient Address */}
          <div>
            <label htmlFor="recipient" className="form-label">
              Recipient Address *
            </label>
            <input
              type="text"
              id="recipient"
              name="recipient"
              value={formData.recipient}
              onChange={handleInputChange}
              placeholder="0x..."
              className="form-input"
              required
            />
            <p className="text-xs text-gray-500 mt-1">
              Address that will receive the PersonaINFT
            </p>
          </div>

          {/* Group ID Selection */}
          <div>
            <label htmlFor="groupId" className="form-label">
              Persona Group *
            </label>
            <div className="space-y-3">
              <input
                type="number"
                id="groupId"
                name="groupId"
                value={formData.groupId}
                onChange={handleInputChange}
                placeholder="Enter Group ID (e.g., 1, 2, 3...)"
                className="form-input"
                min="1"
                required
              />
              <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
                <p className="text-sm text-yellow-800">
                  <strong>Note:</strong> Enter the Group ID of an existing
                  persona group. You can only mint INFTs for groups you've
                  created or have admin access to.
                </p>
              </div>
            </div>
          </div>

          {/* Personality Traits */}
          <div>
            <label htmlFor="personalityTraits" className="form-label">
              Individual Personality Traits *
            </label>
            <textarea
              id="personalityTraits"
              name="personalityTraits"
              value={formData.personalityTraits}
              onChange={handleInputChange}
              placeholder="e.g., Helpful, professional, detail-oriented, creative, enthusiastic..."
              className="form-textarea"
              rows={4}
              required
            />
            <p className="text-xs text-gray-500 mt-1">
              Specific personality traits for this individual INFT. This will
              customize how the AI agent behaves for this particular NFT holder.
            </p>
          </div>

          {/* Info Box */}
          <div className="bg-green-50 border border-green-200 rounded-lg p-4">
            <div className="flex">
              <div className="flex-shrink-0">
                <svg
                  className="h-5 w-5 text-green-400"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fillRule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                    clipRule="evenodd"
                  />
                </svg>
              </div>
              <div className="ml-3">
                <h3 className="text-sm font-medium text-green-800">
                  What happens after minting
                </h3>
                <div className="mt-2 text-sm text-green-700">
                  <ul className="list-disc list-inside space-y-1">
                    <li>
                      The recipient will own an INFT that grants access to the
                      AI agent
                    </li>
                    <li>
                      They can interact with the AI through the chat interface
                    </li>
                    <li>
                      The AI will respond based on the group's knowledge base +
                      individual traits
                    </li>
                    <li>
                      The INFT can be transferred to other users (transferring
                      agent access)
                    </li>
                    <li>
                      Raw data remains encrypted and controlled by the group
                      admin
                    </li>
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
                  ? "Minting..."
                  : "Mint PersonaINFT"}
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

      {/* Quick Start Guide */}
      <div className="mt-8 bg-gray-50 rounded-lg p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Quick Start Guide
        </h3>
        <div className="space-y-4">
          <div className="flex items-start space-x-3">
            <div className="flex-shrink-0 w-6 h-6 bg-primary-100 text-primary-600 rounded-full flex items-center justify-center text-sm font-semibold">
              1
            </div>
            <div>
              <h4 className="font-medium text-gray-900">
                Create a Persona Group First
              </h4>
              <p className="text-sm text-gray-600">
                Go to the "Create Group" tab to set up a persona group with AI
                data before minting INFTs.
              </p>
            </div>
          </div>
          <div className="flex items-start space-x-3">
            <div className="flex-shrink-0 w-6 h-6 bg-primary-100 text-primary-600 rounded-full flex items-center justify-center text-sm font-semibold">
              2
            </div>
            <div>
              <h4 className="font-medium text-gray-900">Note the Group ID</h4>
              <p className="text-sm text-gray-600">
                After creating a group, note down the Group ID from the
                transaction logs or events.
              </p>
            </div>
          </div>
          <div className="flex items-start space-x-3">
            <div className="flex-shrink-0 w-6 h-6 bg-primary-100 text-primary-600 rounded-full flex items-center justify-center text-sm font-semibold">
              3
            </div>
            <div>
              <h4 className="font-medium text-gray-900">Mint & Interact</h4>
              <p className="text-sm text-gray-600">
                Use that Group ID here to mint INFTs, then go to "AI Chat" to
                interact with your agent.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MintPersonaINFT;
