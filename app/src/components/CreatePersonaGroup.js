import React, { useState } from "react";
import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { toast } from "react-hot-toast";
import { keccak256, toBytes } from "viem";
import { PERSONA_INFT_ABI, CONTRACT_ADDRESSES } from "../config/contracts";

const CreatePersonaGroup = () => {
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    encryptedDataURI: "",
    personalityData: "",
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

  const generateMockEncryptedData = (personalityData) => {
    // In a real implementation, this would encrypt the data with the central server's public key
    // For demo purposes, we'll create a mock encrypted URI and hash
    const mockEncryptedData = `encrypted_${Date.now()}_${Math.random()
      .toString(36)
      .substr(2, 9)}`;
    const mockURI = `0g://storage/persona-${mockEncryptedData}`;
    const dataHash = keccak256(toBytes(personalityData + mockEncryptedData));

    return { mockURI, dataHash };
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.name || !formData.description || !formData.personalityData) {
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
      // Generate mock encrypted data (in real app, this would be done server-side)
      const { mockURI, dataHash } = generateMockEncryptedData(
        formData.personalityData
      );

      // Update form data with generated URI
      setFormData((prev) => ({ ...prev, encryptedDataURI: mockURI }));

      await writeContract({
        address: CONTRACT_ADDRESSES.PERSONA_INFT,
        abi: PERSONA_INFT_ABI,
        functionName: "createPersonaGroup",
        args: [formData.name, formData.description, mockURI, dataHash],
      });

      toast.success("Transaction submitted! Waiting for confirmation...");
    } catch (error) {
      console.error("Error creating persona group:", error);
      toast.error(error.message || "Failed to create persona group");
      setIsLoading(false);
    }
  };

  // Handle transaction success
  React.useEffect(() => {
    if (isSuccess) {
      toast.success("Persona Group created successfully!");
      setFormData({
        name: "",
        description: "",
        encryptedDataURI: "",
        personalityData: "",
      });
      setIsLoading(false);
    }
  }, [isSuccess]);

  const isSubmitting = isLoading || isConfirming;

  return (
    <div className="max-w-2xl mx-auto">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-gray-900">
            Create Persona Group
          </h2>
          <p className="text-gray-600 mt-2">
            Set up a new persona group with centrally managed AI data. This will
            create the foundation for minting INFTs.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Name Field */}
          <div>
            <label htmlFor="name" className="form-label">
              Persona Name *
            </label>
            <input
              type="text"
              id="name"
              name="name"
              value={formData.name}
              onChange={handleInputChange}
              placeholder="e.g., AI Assistant, Shakespeare Bot, Technical Advisor"
              className="form-input"
              required
            />
            <p className="text-xs text-gray-500 mt-1">
              A unique name for your AI persona
            </p>
          </div>

          {/* Description Field */}
          <div>
            <label htmlFor="description" className="form-label">
              Description *
            </label>
            <textarea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              placeholder="Describe what this AI persona does, its expertise, and personality..."
              className="form-textarea"
              rows={3}
              required
            />
            <p className="text-xs text-gray-500 mt-1">
              Detailed description of the AI persona's capabilities and purpose
            </p>
          </div>

          {/* Personality Data Field */}
          <div>
            <label htmlFor="personalityData" className="form-label">
              Personality & Training Data *
            </label>
            <textarea
              id="personalityData"
              name="personalityData"
              value={formData.personalityData}
              onChange={handleInputChange}
              placeholder="Enter personality traits, knowledge base, conversation style, expertise areas, etc..."
              className="form-textarea"
              rows={6}
              required
            />
            <p className="text-xs text-gray-500 mt-1">
              This data will be encrypted and stored centrally. Include
              personality traits, knowledge areas, conversation style, etc.
            </p>
          </div>

          {/* Generated URI Display */}
          {formData.encryptedDataURI && (
            <div>
              <label className="form-label">Generated Storage URI</label>
              <div className="bg-gray-50 rounded-lg p-3 font-mono text-sm text-gray-700">
                {formData.encryptedDataURI}
              </div>
              <p className="text-xs text-gray-500 mt-1">
                This URI points to your encrypted persona data on 0G Storage
              </p>
            </div>
          )}

          {/* Info Box */}
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
                  How it works
                </h3>
                <div className="mt-2 text-sm text-blue-700">
                  <ul className="list-disc list-inside space-y-1">
                    <li>
                      Your personality data will be encrypted with the central
                      server's public key
                    </li>
                    <li>
                      Only the central server can decrypt and use this data for
                      AI inference
                    </li>
                    <li>
                      INFT holders will interact with the AI agent, not the raw
                      data
                    </li>
                    <li>
                      You maintain full control over updates and access to this
                      group
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
                  ? "Creating..."
                  : "Create Persona Group"}
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
    </div>
  );
};

export default CreatePersonaGroup;
