// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IPersonaAgent.sol";
import "./PersonaINFT.sol";
import "./PersonaStorageManager.sol";

/**
 * @title PersonaAgentManager
 * @dev Manages AI agent interactions for PersonaINFTs
 *
 * Key Features:
 * - Processes queries through 0G Compute
 * - Maintains interaction history
 * - Enforces access control based on NFT ownership
 * - Integrates with central storage for persona data
 */
contract PersonaAgentManager is IPersonaAgent, AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_OPERATOR_ROLE = keccak256("AGENT_OPERATOR_ROLE");

    struct InteractionRecord {
        uint256 tokenId;
        address requester;
        string query;
        string response;
        uint256 timestamp;
        bytes metadata;
    }

    struct AgentStats {
        uint256 totalInteractions;
        uint256 lastInteraction;
        uint256 averageResponseTime;
        bool isActive;
    }

    // Contract references
    PersonaINFT public personaINFT;
    PersonaStorageManager public storageManager;

    // Storage
    mapping(uint256 => PersonaConfig) private personaConfigs;
    mapping(uint256 => InteractionRecord[]) private interactionHistory;
    mapping(uint256 => AgentStats) private agentStats;
    mapping(address => bool) private authorizedCallers;

    // 0G Infrastructure
    address public ogComputeAddress;
    string public agentModelEndpoint;

    // Configuration
    uint256 public maxHistoryLength = 100;
    uint256 public maxQueryLength = 2000;
    uint256 public maxResponseTime = 30 seconds;

    // Events
    event AgentConfigured(uint256 indexed tokenId, string name, string personalityTraits);

    event QueryProcessed(uint256 indexed tokenId, address indexed requester, uint256 responseTime);

    event AgentDeactivated(uint256 indexed tokenId, string reason);

    constructor(
        address _personaINFT,
        address _storageManager,
        address _ogComputeAddress,
        string memory _agentModelEndpoint
    ) {
        require(_personaINFT != address(0), "Invalid PersonaINFT address");
        require(_storageManager != address(0), "Invalid StorageManager address");
        require(_ogComputeAddress != address(0), "Invalid OGCompute address");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(AGENT_OPERATOR_ROLE, msg.sender);

        personaINFT = PersonaINFT(_personaINFT);
        storageManager = PersonaStorageManager(_storageManager);
        ogComputeAddress = _ogComputeAddress;
        agentModelEndpoint = _agentModelEndpoint;

        // Authorize the PersonaINFT contract to call agent functions
        authorizedCallers[_personaINFT] = true;
    }

    /**
     * @dev Process a query through the AI agent
     * @param request The agent request structure
     * @return response The agent's response
     */
    function processQuery(AgentRequest calldata request)
        external
        override
        nonReentrant
        returns (AgentResponse memory response)
    {
        require(authorizedCallers[msg.sender] || hasRole(AGENT_OPERATOR_ROLE, msg.sender), "Unauthorized caller");
        require(bytes(request.query).length <= maxQueryLength, "Query too long");
        require(bytes(request.query).length > 0, "Empty query");

        // Verify token ownership and access
        require(personaINFT.ownerOf(request.tokenId) == request.requester, "Not token owner");

        // Get persona token info
        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(request.tokenId);
        require(token.isActive, "Token not active");

        // Get storage group info
        PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(token.groupId);
        require(group.isActive, "Group not active");

        uint256 startTime = block.timestamp;

        // Process query through 0G Compute
        string memory agentResponse = _processWithOGCompute(
            request.tokenId, group.encryptedDataURI, token.personalityTraits, request.query, request.context
        );

        uint256 responseTime = block.timestamp - startTime;
        require(responseTime <= maxResponseTime, "Response timeout");

        // Create response
        response = AgentResponse({
            tokenId: request.tokenId,
            response: agentResponse,
            timestamp: block.timestamp,
            metadata: abi.encode(responseTime, group.name, token.personalityTraits)
        });

        // Record interaction
        _recordInteraction(request, response);

        // Update stats
        _updateAgentStats(request.tokenId, responseTime);

        emit AgentQueryProcessed(request.tokenId, request.requester, request.query, agentResponse);
        emit QueryProcessed(request.tokenId, request.requester, responseTime);
    }

    /**
     * @dev Get persona configuration for a token
     * @param tokenId The token ID
     * @return config The persona configuration
     */
    function getPersonaConfig(uint256 tokenId) external view override returns (PersonaConfig memory config) {
        require(_tokenExists(tokenId), "Token does not exist");

        if (bytes(personaConfigs[tokenId].name).length > 0) {
            return personaConfigs[tokenId];
        }

        // Fallback to token data if no custom config
        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
        PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(token.groupId);

        return PersonaConfig({
            name: group.name,
            description: group.description,
            personalityTraits: token.personalityTraits,
            knowledgeBase: group.encryptedDataURI,
            isActive: token.isActive && group.isActive
        });
    }

    /**
     * @dev Update persona configuration (restricted access)
     * @param tokenId The token ID
     * @param config New persona configuration
     */
    function updatePersonaConfig(uint256 tokenId, PersonaConfig calldata config) external override {
        require(_tokenExists(tokenId), "Token does not exist");
        require(personaINFT.ownerOf(tokenId) == msg.sender || hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        require(bytes(config.name).length > 0, "Name cannot be empty");

        personaConfigs[tokenId] = config;

        emit PersonaConfigUpdated(tokenId, config.name, config.personalityTraits);
        emit AgentConfigured(tokenId, config.name, config.personalityTraits);
    }

    /**
     * @dev Simple function to update just the config data (for testing convenience)
     * @param tokenId The token ID
     * @param configData The new configuration data
     */
    function updatePersonaConfigData(uint256 tokenId, string memory configData) external {
        require(_tokenExists(tokenId), "Token does not exist");
        require(personaINFT.ownerOf(tokenId) == msg.sender || hasRole(ADMIN_ROLE, msg.sender), "Not authorized");

        PersonaConfig storage config = personaConfigs[tokenId];
        config.description = configData;
        config.isActive = true;

        // Set default values if not set
        if (bytes(config.name).length == 0) {
            config.name = "Default Persona";
        }

        emit PersonaConfigUpdated(tokenId, config.name, configData);
    }

    /**
     * @dev Check if token has access to agent services
     * @param tokenId The token ID
     * @param requester The address requesting access
     * @return hasAccess Whether access is granted
     */
    function hasAgentAccess(uint256 tokenId, address requester) external view override returns (bool hasAccess) {
        if (!_tokenExists(tokenId)) {
            return false;
        }

        try personaINFT.ownerOf(tokenId) returns (address owner) {
            if (owner != requester) {
                return false;
            }
        } catch {
            return false;
        }

        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
        if (!token.isActive) {
            return false;
        }

        PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(token.groupId);
        return group.isActive && agentStats[tokenId].isActive;
    }

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
        override
        returns (AgentRequest[] memory requests, AgentResponse[] memory responses)
    {
        require(_tokenExists(tokenId), "Token does not exist");
        require(
            personaINFT.ownerOf(tokenId) == msg.sender || hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized to view history"
        );

        InteractionRecord[] storage history = interactionHistory[tokenId];
        uint256 length = history.length;

        if (limit == 0 || limit > length) {
            limit = length;
        }

        requests = new AgentRequest[](limit);
        responses = new AgentResponse[](limit);

        // Return most recent interactions first
        for (uint256 i = 0; i < limit; i++) {
            InteractionRecord storage record = history[length - 1 - i];

            requests[i] = AgentRequest({
                tokenId: record.tokenId,
                requester: record.requester,
                query: record.query,
                timestamp: record.timestamp,
                context: record.metadata
            });

            responses[i] = AgentResponse({
                tokenId: record.tokenId,
                response: record.response,
                timestamp: record.timestamp,
                metadata: record.metadata
            });
        }
    }

    /**
     * @dev Get simplified interaction history for testing
     * @param tokenId The token ID
     * @param start Starting index
     * @param limit Maximum number of interactions to return
     * @return records Array of interaction records
     */
    function getInteractionRecords(uint256 tokenId, uint256 start, uint256 limit)
        external
        view
        returns (InteractionRecord[] memory records)
    {
        require(_tokenExists(tokenId), "Token does not exist");

        InteractionRecord[] storage history = interactionHistory[tokenId];
        uint256 length = history.length;

        if (start >= length) {
            return new InteractionRecord[](0);
        }

        uint256 end = start + limit;
        if (end > length) {
            end = length;
        }

        uint256 recordCount = end - start;
        records = new InteractionRecord[](recordCount);

        for (uint256 i = 0; i < recordCount; i++) {
            records[i] = history[start + i];
        }
    }

    /**
     * @dev Get agent statistics for a token
     * @param tokenId The token ID
     */
    function getAgentStats(uint256 tokenId) external view returns (AgentStats memory stats) {
        require(_tokenExists(tokenId), "Token does not exist");
        return agentStats[tokenId];
    }

    /**
     * @dev Deactivate an agent (admin only)
     * @param tokenId The token ID
     * @param reason Reason for deactivation
     */
    function deactivateAgent(uint256 tokenId, string memory reason) external onlyRole(ADMIN_ROLE) {
        require(_tokenExists(tokenId), "Token does not exist");

        agentStats[tokenId].isActive = false;

        emit AgentDeactivated(tokenId, reason);
    }

    /**
     * @dev Activate an agent (admin only)
     * @param tokenId The token ID
     */
    function activateAgent(uint256 tokenId) external onlyRole(ADMIN_ROLE) {
        require(_tokenExists(tokenId), "Token does not exist");

        agentStats[tokenId].isActive = true;
    }

    /**
     * @dev Add authorized caller (admin only)
     * @param caller Address to authorize
     */
    function addAuthorizedCaller(address caller) external onlyRole(ADMIN_ROLE) {
        authorizedCallers[caller] = true;
    }

    /**
     * @dev Remove authorized caller (admin only)
     * @param caller Address to remove authorization
     */
    function removeAuthorizedCaller(address caller) external onlyRole(ADMIN_ROLE) {
        authorizedCallers[caller] = false;
    }

    /**
     * @dev Update configuration parameters (admin only)
     * @param _maxHistoryLength New max history length
     * @param _maxQueryLength New max query length
     * @param _maxResponseTime New max response time
     */
    function updateConfiguration(uint256 _maxHistoryLength, uint256 _maxQueryLength, uint256 _maxResponseTime)
        external
        onlyRole(ADMIN_ROLE)
    {
        maxHistoryLength = _maxHistoryLength;
        maxQueryLength = _maxQueryLength;
        maxResponseTime = _maxResponseTime;
    }

    /**
     * @dev Update 0G Compute configuration (admin only)
     * @param _ogComputeAddress New 0G Compute address
     * @param _agentModelEndpoint New agent model endpoint
     */
    function updateOGComputeConfig(address _ogComputeAddress, string memory _agentModelEndpoint)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(_ogComputeAddress != address(0), "Invalid address");

        ogComputeAddress = _ogComputeAddress;
        agentModelEndpoint = _agentModelEndpoint;
    }

    // Internal functions

    /**
     * @dev Process query with 0G Compute (placeholder implementation)
     * @param tokenId Token ID for context
     * @param encryptedDataURI URI to encrypted persona data
     * @param personalityTraits Individual personality traits
     * @param query User query
     * @param context Additional context
     * @return response AI agent response
     */
    function _processWithOGCompute(
        uint256 tokenId,
        string memory encryptedDataURI,
        string memory personalityTraits,
        string memory query,
        bytes memory context
    ) internal view returns (string memory response) {
        // This is a placeholder implementation
        // In production, this would:
        // 1. Call 0G Compute API with encrypted data URI
        // 2. Include personality traits and context
        // 3. Process query with AI model
        // 4. Return personalized response

        response = string(
            abi.encodePacked(
                "AI Agent Response for token ",
                Strings.toString(tokenId),
                ": Based on personality '",
                personalityTraits,
                "' and data from '",
                encryptedDataURI,
                "', responding to: '",
                query,
                "'"
            )
        );
    }

    /**
     * @dev Record interaction in history
     * @param request Original request
     * @param response Agent response
     */
    function _recordInteraction(AgentRequest memory request, AgentResponse memory response) internal {
        InteractionRecord[] storage history = interactionHistory[request.tokenId];

        // Maintain history limit
        if (history.length >= maxHistoryLength) {
            // Remove oldest interaction
            for (uint256 i = 0; i < history.length - 1; i++) {
                history[i] = history[i + 1];
            }
            history.pop();
        }

        history.push(
            InteractionRecord({
                tokenId: request.tokenId,
                requester: request.requester,
                query: request.query,
                response: response.response,
                timestamp: response.timestamp,
                metadata: response.metadata
            })
        );
    }

    /**
     * @dev Update agent statistics
     * @param tokenId Token ID
     * @param responseTime Response time for this interaction
     */
    function _updateAgentStats(uint256 tokenId, uint256 responseTime) internal {
        AgentStats storage stats = agentStats[tokenId];

        if (!stats.isActive) {
            stats.isActive = true;
        }

        stats.totalInteractions++;
        stats.lastInteraction = block.timestamp;

        // Update average response time
        if (stats.totalInteractions == 1) {
            stats.averageResponseTime = responseTime;
        } else {
            stats.averageResponseTime =
                (stats.averageResponseTime * (stats.totalInteractions - 1) + responseTime) / stats.totalInteractions;
        }
    }

    /**
     * @dev Check if token exists
     * @param tokenId Token ID to check
     */
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        try personaINFT.ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }
}
