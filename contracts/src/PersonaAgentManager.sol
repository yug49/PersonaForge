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

    // AI Request tracking
    struct AIRequest {
        uint256 tokenId;
        address requester;
        string query;
        uint256 timestamp;
        bool processed;
        string response;
    }

    mapping(uint256 => AIRequest) public aiRequests;
    uint256 public requestCounter;

    // Configuration
    uint256 public maxHistoryLength = 100;
    uint256 public maxQueryLength = 2000;

    // Events for off-chain AI processing
    event AIRequestCreated(
        uint256 indexed requestId,
        uint256 indexed tokenId,
        address indexed requester,
        string encryptedDataURI,
        string personalityTraits,
        string query,
        bytes context,
        uint256 timestamp
    );

    event AIResponseSubmitted(
        uint256 indexed requestId,
        uint256 indexed tokenId,
        string response,
        uint256 timestamp
    );

    event AgentConfigUpdated(uint256 indexed tokenId, address indexed updater, uint256 timestamp);

    event AuthorizedCallerAdded(address indexed caller);
    
    event AuthorizedCallerRemoved(address indexed caller);

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

        // Create AI request
        uint256 requestId = requestCounter++;
        
        aiRequests[requestId] = AIRequest({
            tokenId: request.tokenId,
            requester: request.requester,
            query: request.query,
            timestamp: block.timestamp,
            processed: false,
            response: ""
        });

        // Emit event for off-chain AI processing
        emit AIRequestCreated(
            requestId,
            request.tokenId,
            request.requester,
            group.encryptedDataURI,  // Server will fetch this from 0G Storage
            token.personalityTraits,
            request.query,
            request.context,
            block.timestamp
        );

        // Record interaction with placeholder response
        _recordInteraction(
            request.tokenId,
            request.requester,
            request.query,
            "AI request submitted. Response pending..."
        );

        // Return immediate response indicating processing
        response = AgentResponse({
            tokenId: request.tokenId,
            response: "AI request submitted. Response will be available shortly.",
            timestamp: block.timestamp,
            metadata: abi.encode(requestId, "event-driven-v1")
        });
    }

    /**
     * @dev Submit AI response from off-chain processing (only authorized server)
     * @param requestId The AI request ID
     * @param response The AI-generated response
     */
    function submitAIResponse(uint256 requestId, string memory response) 
        external 
        onlyRole(ADMIN_ROLE)
        nonReentrant
    {
        require(requestId < requestCounter, "Invalid request ID");
        require(!aiRequests[requestId].processed, "Request already processed");
        require(bytes(response).length > 0, "Empty response");

        AIRequest storage request = aiRequests[requestId];
        request.processed = true;
        request.response = response;

        // Update interaction history with actual response
        _updateInteractionResponse(request.tokenId, response);

        // Update agent stats
        _updateAgentStats(request.tokenId, 0); // Response time handled off-chain

        emit AIResponseSubmitted(requestId, request.tokenId, response, block.timestamp);
    }

    /**
     * @dev Get AI response for a request
     * @param requestId The AI request ID
     * @return response The AI response (if processed)
     */
    function getAIResponse(uint256 requestId) external view returns (string memory) {
        require(requestId < requestCounter, "Invalid request ID");
        require(aiRequests[requestId].processed, "Response not ready");
        return aiRequests[requestId].response;
    }

    /**
     * @dev Check if AI request is processed
     * @param requestId The AI request ID
     * @return processed Whether the request has been processed
     */
    function isAIRequestProcessed(uint256 requestId) external view returns (bool) {
        if (requestId >= requestCounter) return false;
        return aiRequests[requestId].processed;
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

        emit AgentConfigUpdated(tokenId, msg.sender, block.timestamp);
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

        try personaINFT.getPersonaToken(tokenId) returns (PersonaINFT.PersonaToken memory token) {
            if (!token.isActive) {
                return false;
            }

            try personaINFT.getPersonaGroup(token.groupId) returns (PersonaINFT.PersonaGroup memory group) {
                return group.isActive; // Agent access depends on token/group being active, not on prior interactions
            } catch {
                return false;
            }
        } catch {
            return false;
        }
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
     */
    function deactivateAgent(uint256 tokenId, string memory /* reason */) external onlyRole(ADMIN_ROLE) {
        require(_tokenExists(tokenId), "Token does not exist");

        agentStats[tokenId].isActive = false;
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
        require(caller != address(0), "Invalid caller address");
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
     */
    function updateConfiguration(uint256 _maxHistoryLength, uint256 _maxQueryLength)
        external
        onlyRole(ADMIN_ROLE)
    {
        maxHistoryLength = _maxHistoryLength;
        maxQueryLength = _maxQueryLength;
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
        require(bytes(_agentModelEndpoint).length > 0, "Endpoint cannot be empty");

        ogComputeAddress = _ogComputeAddress;
        agentModelEndpoint = _agentModelEndpoint;
    }

    // Internal functions

    /**
     * @dev Record interaction in history (simplified for event-driven approach)
     * @param tokenId Token ID
     * @param requester Address of requester
     * @param query User query
     * @param response Agent response
     */
    function _recordInteraction(
        uint256 tokenId,
        address requester,
        string memory query,
        string memory response
    ) internal {
        InteractionRecord[] storage history = interactionHistory[tokenId];

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
                tokenId: tokenId,
                requester: requester,
                query: query,
                response: response,
                timestamp: block.timestamp,
                metadata: abi.encode("event-driven-request")
            })
        );
    }

    /**
     * @dev Update the most recent interaction with actual AI response
     * @param tokenId Token ID
     * @param response Actual AI response
     */
    function _updateInteractionResponse(uint256 tokenId, string memory response) internal {
        InteractionRecord[] storage history = interactionHistory[tokenId];
        if (history.length > 0) {
            // Update the most recent interaction
            history[history.length - 1].response = response;
        }
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
