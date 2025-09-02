// Contract ABIs and configurations for PersonaForge

export const PERSONA_INFT_ABI = [
  // Events
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "groupId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "address",
        name: "admin",
        type: "address",
      },
      { indexed: false, internalType: "string", name: "name", type: "string" },
    ],
    name: "PersonaGroupCreated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "groupId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: false,
        internalType: "string",
        name: "personalityTraits",
        type: "string",
      },
    ],
    name: "PersonaMinted",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      { indexed: true, internalType: "address", name: "user", type: "address" },
      {
        indexed: false,
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
    ],
    name: "AgentInteraction",
    type: "event",
  },
  // Read Functions
  {
    inputs: [{ internalType: "uint256", name: "groupId", type: "uint256" }],
    name: "getPersonaGroup",
    outputs: [
      {
        components: [
          { internalType: "string", name: "name", type: "string" },
          { internalType: "string", name: "description", type: "string" },
          { internalType: "address", name: "admin", type: "address" },
          { internalType: "string", name: "encryptedDataURI", type: "string" },
          { internalType: "bytes32", name: "dataHash", type: "bytes32" },
          { internalType: "uint256", name: "lastUpdated", type: "uint256" },
          { internalType: "bool", name: "isActive", type: "bool" },
          { internalType: "uint256[]", name: "tokenIds", type: "uint256[]" },
        ],
        internalType: "struct PersonaINFT.PersonaGroup",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "tokenId", type: "uint256" }],
    name: "getPersonaToken",
    outputs: [
      {
        components: [
          { internalType: "uint256", name: "groupId", type: "uint256" },
          { internalType: "string", name: "personalityTraits", type: "string" },
          { internalType: "uint256", name: "mintedAt", type: "uint256" },
          { internalType: "uint256", name: "lastInteraction", type: "uint256" },
          { internalType: "bool", name: "isActive", type: "bool" },
        ],
        internalType: "struct PersonaINFT.PersonaToken",
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "address", name: "user", type: "address" }],
    name: "getUserTokens",
    outputs: [{ internalType: "uint256[]", name: "", type: "uint256[]" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "tokenId", type: "uint256" }],
    name: "ownerOf",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "user", type: "address" },
      { internalType: "uint256", name: "tokenId", type: "uint256" },
    ],
    name: "canAccessAgent",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "view",
    type: "function",
  },
  // Write Functions
  {
    inputs: [
      { internalType: "string", name: "name", type: "string" },
      { internalType: "string", name: "description", type: "string" },
      { internalType: "string", name: "encryptedDataURI", type: "string" },
      { internalType: "bytes32", name: "dataHash", type: "bytes32" },
    ],
    name: "createPersonaGroup",
    outputs: [{ internalType: "uint256", name: "groupId", type: "uint256" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "to", type: "address" },
      { internalType: "uint256", name: "groupId", type: "uint256" },
      { internalType: "string", name: "personalityTraits", type: "string" },
    ],
    name: "mintPersonaINFT",
    outputs: [{ internalType: "uint256", name: "tokenId", type: "uint256" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "uint256", name: "tokenId", type: "uint256" },
      { internalType: "string", name: "query", type: "string" },
    ],
    name: "interactWithAgent",
    outputs: [{ internalType: "string", name: "response", type: "string" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "from", type: "address" },
      { internalType: "address", name: "to", type: "address" },
      { internalType: "uint256", name: "tokenId", type: "uint256" },
    ],
    name: "transferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export const STORAGE_MANAGER_ABI = [
  // Events
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "groupId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "address",
        name: "admin",
        type: "address",
      },
      { indexed: false, internalType: "string", name: "name", type: "string" },
      {
        indexed: false,
        internalType: "bytes32",
        name: "encryptionKeyHash",
        type: "bytes32",
      },
    ],
    name: "StorageGroupCreated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "groupId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "string",
        name: "newStorageURI",
        type: "string",
      },
      {
        indexed: false,
        internalType: "bytes32",
        name: "newDataHash",
        type: "bytes32",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "version",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "updater",
        type: "address",
      },
    ],
    name: "DataUpdated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "groupId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "address",
        name: "author",
        type: "address",
      },
      {
        indexed: false,
        internalType: "string",
        name: "entryType",
        type: "string",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "bytes32",
        name: "contentHash",
        type: "bytes32",
      },
    ],
    name: "JournalEntryAdded",
    type: "event",
  },
  // Read Functions
  {
    inputs: [{ internalType: "uint256", name: "groupId", type: "uint256" }],
    name: "getStorageGroupInfo",
    outputs: [
      { internalType: "string", name: "name", type: "string" },
      { internalType: "address", name: "admin", type: "address" },
      { internalType: "string", name: "storageURI", type: "string" },
      { internalType: "bytes32", name: "dataHash", type: "bytes32" },
      { internalType: "uint256", name: "lastUpdated", type: "uint256" },
      { internalType: "uint256", name: "version", type: "uint256" },
      { internalType: "bool", name: "isActive", type: "bool" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getTotalGroups",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getCentralServerPublicKey",
    outputs: [{ internalType: "string", name: "", type: "string" }],
    stateMutability: "view",
    type: "function",
  },
  // Write Functions
  {
    inputs: [
      { internalType: "string", name: "name", type: "string" },
      { internalType: "bytes32", name: "encryptionKeyHash", type: "bytes32" },
      { internalType: "string", name: "initialStorageURI", type: "string" },
      { internalType: "bytes32", name: "initialDataHash", type: "bytes32" },
    ],
    name: "createStorageGroup",
    outputs: [{ internalType: "uint256", name: "groupId", type: "uint256" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "uint256", name: "groupId", type: "uint256" },
      { internalType: "string", name: "newStorageURI", type: "string" },
      { internalType: "bytes32", name: "newDataHash", type: "bytes32" },
      { internalType: "string", name: "updateReason", type: "string" },
    ],
    name: "updatePersonaData",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  // Daily Sync Functions
  {
    inputs: [
      { internalType: "uint256", name: "groupId", type: "uint256" },
      { internalType: "string", name: "dailyThoughts", type: "string" },
    ],
    name: "dailySync",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "uint256", name: "groupId", type: "uint256" },
      { internalType: "string", name: "entryContent", type: "string" },
      { internalType: "string", name: "entryType", type: "string" },
    ],
    name: "addJournalEntry",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "uint256", name: "groupId", type: "uint256" },
      { internalType: "uint256", name: "start", type: "uint256" },
      { internalType: "uint256", name: "limit", type: "uint256" },
    ],
    name: "getJournalEntries",
    outputs: [
      {
        components: [
          { internalType: "uint256", name: "groupId", type: "uint256" },
          { internalType: "string", name: "entryContent", type: "string" },
          { internalType: "string", name: "entryType", type: "string" },
          { internalType: "uint256", name: "timestamp", type: "uint256" },
          { internalType: "address", name: "author", type: "address" },
          { internalType: "bytes32", name: "contentHash", type: "bytes32" },
        ],
        internalType: "struct PersonaStorageManager.JournalEntry[]",
        name: "entries",
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "uint256", name: "groupId", type: "uint256" },
      { internalType: "uint256", name: "limit", type: "uint256" },
    ],
    name: "getLatestJournalEntries",
    outputs: [
      {
        components: [
          { internalType: "uint256", name: "groupId", type: "uint256" },
          { internalType: "string", name: "entryContent", type: "string" },
          { internalType: "string", name: "entryType", type: "string" },
          { internalType: "uint256", name: "timestamp", type: "uint256" },
          { internalType: "address", name: "author", type: "address" },
          { internalType: "bytes32", name: "contentHash", type: "bytes32" },
        ],
        internalType: "struct PersonaStorageManager.JournalEntry[]",
        name: "entries",
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "groupId", type: "uint256" }],
    name: "getJournalEntryCount",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
];

export const AGENT_MANAGER_ABI = [
  // Events for event-driven AI processing
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "requestId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "address",
        name: "requester",
        type: "address",
      },
      {
        indexed: false,
        internalType: "string",
        name: "encryptedDataURI",
        type: "string",
      },
      {
        indexed: false,
        internalType: "string",
        name: "personalityTraits",
        type: "string",
      },
      { indexed: false, internalType: "string", name: "query", type: "string" },
      { indexed: false, internalType: "bytes", name: "context", type: "bytes" },
      {
        indexed: false,
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
    ],
    name: "AIRequestCreated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "requestId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "string",
        name: "response",
        type: "string",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
    ],
    name: "AIResponseSubmitted",
    type: "event",
  },
  // Read Functions
  {
    inputs: [
      { internalType: "uint256", name: "tokenId", type: "uint256" },
      { internalType: "address", name: "requester", type: "address" },
    ],
    name: "hasAgentAccess",
    outputs: [{ internalType: "bool", name: "hasAccess", type: "bool" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "tokenId", type: "uint256" }],
    name: "getAgentStats",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "totalInteractions",
            type: "uint256",
          },
          { internalType: "uint256", name: "lastInteraction", type: "uint256" },
          {
            internalType: "uint256",
            name: "averageResponseTime",
            type: "uint256",
          },
          { internalType: "bool", name: "isActive", type: "bool" },
        ],
        internalType: "struct PersonaAgentManager.AgentStats",
        name: "stats",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "requestId", type: "uint256" }],
    name: "getAIResponse",
    outputs: [{ internalType: "string", name: "", type: "string" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "requestId", type: "uint256" }],
    name: "isAIRequestProcessed",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "uint256", name: "tokenId", type: "uint256" },
      { internalType: "uint256", name: "start", type: "uint256" },
      { internalType: "uint256", name: "limit", type: "uint256" },
    ],
    name: "getInteractionRecords",
    outputs: [
      {
        components: [
          { internalType: "uint256", name: "tokenId", type: "uint256" },
          { internalType: "address", name: "requester", type: "address" },
          { internalType: "string", name: "query", type: "string" },
          { internalType: "string", name: "response", type: "string" },
          { internalType: "uint256", name: "timestamp", type: "uint256" },
          { internalType: "bytes", name: "metadata", type: "bytes" },
        ],
        internalType: "struct PersonaAgentManager.InteractionRecord[]",
        name: "records",
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

// Contract addresses (will be loaded from environment)
export const CONTRACT_ADDRESSES = {
  PERSONA_INFT: process.env.REACT_APP_PERSONA_INFT_ADDRESS || "",
  STORAGE_MANAGER: process.env.REACT_APP_STORAGE_MANAGER_ADDRESS || "",
  AGENT_MANAGER: process.env.REACT_APP_AGENT_MANAGER_ADDRESS || "",
};

// 0G Network Configuration
export const OG_NETWORK = {
  id: 16601, // OG-Galileo-Testnet
  name: "OG-Galileo-Testnet",
  network: "og-galileo-testnet",
  nativeCurrency: {
    decimals: 18,
    name: "0G Token",
    symbol: "0G",
  },
  rpcUrls: {
    public: {
      http: ["https://evmrpc-testnet.0g.ai"],
    },
    default: {
      http: ["https://evmrpc-testnet.0g.ai"],
    },
  },
  blockExplorers: {
    default: {
      name: "0G Explorer",
      url: "https://chainscan-newton.0g.ai",
    },
  },
  testnet: true,
};

export const SUPPORTED_CHAINS = [OG_NETWORK];
