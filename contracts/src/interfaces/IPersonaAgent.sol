// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPersonaAgent
 * @dev Interface for interacting with AI agents through PersonaINFTs
 */
interface IPersonaAgent {
    /**
     * @dev Structure for agent interaction requests
     */
    struct AgentRequest {
        uint256 tokenId;
        address requester;
        string query;
        uint256 timestamp;
        bytes context; // Additional context data
    }

    /**
     * @dev Structure for agent responses
     */
    struct AgentResponse {
        uint256 tokenId;
        string response;
        uint256 timestamp;
        bytes metadata; // Response metadata
    }

    /**
     * @dev Structure for persona configuration
     */
    struct PersonaConfig {
        string name;
        string description;
        string personalityTraits;
        string knowledgeBase;
        bool isActive;
    }

    /**
     * @dev Emitted when an agent processes a query
     */
    event AgentQueryProcessed(uint256 indexed tokenId, address indexed requester, string query, string response);

    /**
     * @dev Emitted when persona configuration is updated
     */
    event PersonaConfigUpdated(uint256 indexed tokenId, string name, string personalityTraits);

    /**
     * @dev Process a query through the AI agent
     * @param request The agent request structure
     * @return response The agent's response
     */
    function processQuery(AgentRequest calldata request) external returns (AgentResponse memory response);

    /**
     * @dev Get persona configuration for a token
     * @param tokenId The token ID
     * @return config The persona configuration
     */
    function getPersonaConfig(uint256 tokenId) external view returns (PersonaConfig memory config);

    /**
     * @dev Update persona configuration (restricted access)
     * @param tokenId The token ID
     * @param config New persona configuration
     */
    function updatePersonaConfig(uint256 tokenId, PersonaConfig calldata config) external;

    /**
     * @dev Check if token has access to agent services
     * @param tokenId The token ID
     * @param requester The address requesting access
     * @return hasAccess Whether access is granted
     */
    function hasAgentAccess(uint256 tokenId, address requester) external view returns (bool hasAccess);

    /**
     * @dev Get agent interaction history for a token
     * @param tokenId The token ID
     * @param limit Maximum number of interactions to return
     * @return requests Array of recent requests
     * @return responses Array of corresponding responses
     */
    function getInteractionHistory(uint256 tokenId, uint256 limit)
        external
        view
        returns (AgentRequest[] memory requests, AgentResponse[] memory responses);
}
