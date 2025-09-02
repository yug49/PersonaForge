// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import "./interfaces/IPersonaAgent.sol"; // Not needed in main contract

/**
 * @title PersonaINFT
 * @dev Intelligent NFTs that grant access to AI agents without transferring underlying data
 *
 * Key Features:
 * - INFTs grant access to AI agents, not raw data
 * - Central storage controlled by group admins
 * - Simple transfers without complex re-encryption
 * - Group-based persona management
 */
contract PersonaINFT is ERC721, AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GROUP_ADMIN_ROLE = keccak256("GROUP_ADMIN_ROLE");

    struct PersonaGroup {
        string name;
        string description;
        address admin;
        string encryptedDataURI; // Points to 0G Storage
        bytes32 dataHash; // Hash of encrypted data
        uint256 lastUpdated;
        bool isActive;
        uint256[] tokenIds; // All INFTs in this group
    }

    struct PersonaToken {
        uint256 groupId;
        string personalityTraits; // Individual traits for this INFT
        uint256 mintedAt;
        uint256 lastInteraction;
        bool isActive;
    }

    // Storage
    mapping(uint256 => PersonaGroup) public personaGroups;
    mapping(uint256 => PersonaToken) public personaTokens;
    mapping(address => uint256[]) public userTokens;

    uint256 private _nextTokenId = 1;

    /**
     * @dev Get the next token ID that will be minted
     * @return The next token ID
     */
    function nextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    uint256 private _nextGroupId = 1;

    /**
     * @dev Get the total number of groups created
     * @return The total number of groups
     */
    function totalGroups() external view returns (uint256) {
        return _nextGroupId - 1;
    }

    // 0G Infrastructure addresses
    address public ogStorageAddress;
    address public ogComputeAddress;

    // Events
    event PersonaGroupCreated(uint256 indexed groupId, address indexed admin, string name);

    event PersonaGroupUpdated(uint256 indexed groupId, bytes32 newDataHash, string newEncryptedDataURI);

    event PersonaMinted(
        uint256 indexed tokenId, uint256 indexed groupId, address indexed owner, string personalityTraits
    );

    event AgentInteraction(uint256 indexed tokenId, address indexed user, uint256 timestamp);

    constructor(string memory name, string memory symbol, address _ogStorageAddress, address _ogComputeAddress)
        ERC721(name, symbol)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        ogStorageAddress = _ogStorageAddress;
        ogComputeAddress = _ogComputeAddress;
    }

    /**
     * @dev Create a new persona group with centrally managed data
     * @param name Name of the persona group
     * @param description Description of the persona
     * @param encryptedDataURI URI pointing to encrypted data on 0G Storage
     * @param dataHash Hash of the encrypted data for verification
     */
    function createPersonaGroup(
        string memory name,
        string memory description,
        string memory encryptedDataURI,
        bytes32 dataHash
    ) external returns (uint256 groupId) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(encryptedDataURI).length > 0, "Data URI cannot be empty");

        groupId = _nextGroupId++;

        personaGroups[groupId] = PersonaGroup({
            name: name,
            description: description,
            admin: msg.sender,
            encryptedDataURI: encryptedDataURI,
            dataHash: dataHash,
            lastUpdated: block.timestamp,
            isActive: true,
            tokenIds: new uint256[](0)
        });

        // Grant group admin role to creator
        _grantRole(GROUP_ADMIN_ROLE, msg.sender);

        emit PersonaGroupCreated(groupId, msg.sender, name);
    }

    /**
     * @dev Update persona group data (only group admin)
     * @param groupId ID of the group to update
     * @param newEncryptedDataURI New encrypted data URI
     * @param newDataHash New data hash
     */
    function updatePersonaGroup(uint256 groupId, string memory newEncryptedDataURI, bytes32 newDataHash) external {
        PersonaGroup storage group = personaGroups[groupId];
        require(group.isActive, "Group not active");
        require(group.admin == msg.sender, "Not group admin");
        require(bytes(newEncryptedDataURI).length > 0, "Data URI cannot be empty");

        group.encryptedDataURI = newEncryptedDataURI;
        group.dataHash = newDataHash;
        group.lastUpdated = block.timestamp;

        emit PersonaGroupUpdated(groupId, newDataHash, newEncryptedDataURI);
    }

    /**
     * @dev Mint a new PersonaINFT that grants access to a specific persona group
     * @param to Address to mint the token to
     * @param groupId ID of the persona group
     * @param personalityTraits Individual personality traits for this INFT
     */
    function mintPersonaINFT(address to, uint256 groupId, string memory personalityTraits)
        external
        nonReentrant
        returns (uint256 tokenId)
    {
        require(to != address(0), "Cannot mint to zero address");

        PersonaGroup storage group = personaGroups[groupId];
        require(group.isActive, "Group not active");
        require(group.admin == msg.sender, "Not group admin");

        tokenId = _nextTokenId++;

        personaTokens[tokenId] = PersonaToken({
            groupId: groupId,
            personalityTraits: personalityTraits,
            mintedAt: block.timestamp,
            lastInteraction: 0,
            isActive: true
        });

        // Add to group's token list
        group.tokenIds.push(tokenId);

        _safeMint(to, tokenId);

        emit PersonaMinted(tokenId, groupId, to, personalityTraits);
    }

    /**
     * @dev Override _update to update user token lists
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        address previousOwner = super._update(to, tokenId, auth);

        if (from != address(0) && to != address(0)) {
            require(personaTokens[tokenId].isActive, "Token not active");

            // Update user token lists
            _removeFromUserTokens(from, tokenId);
            userTokens[to].push(tokenId);
        } else if (from == address(0) && to != address(0)) {
            // Minting case
            userTokens[to].push(tokenId);
        }

        return previousOwner;
    }

    /**
     * @dev Interact with AI agent (only token owner)
     * @param tokenId Token ID to interact with
     * @param query User's query to the agent
     * @return response Agent's response
     */
    function interactWithAgent(uint256 tokenId, string memory query) external returns (string memory response) {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(personaTokens[tokenId].isActive, "Token not active");

        PersonaToken storage token = personaTokens[tokenId];
        PersonaGroup storage group = personaGroups[token.groupId];
        require(group.isActive, "Group not active");

        // Update last interaction
        token.lastInteraction = block.timestamp;

        // Call 0G Compute for AI inference (simplified interface)
        // In real implementation, this would call 0G Compute API
        response = _processAgentQuery(tokenId, group.encryptedDataURI, token.personalityTraits, query);

        emit AgentInteraction(tokenId, msg.sender, block.timestamp);
    }

    /**
     * @dev Get persona group information
     */
    function getPersonaGroup(uint256 groupId) external view returns (PersonaGroup memory) {
        require(personaGroups[groupId].isActive, "Group not active");
        return personaGroups[groupId];
    }

    /**
     * @dev Get persona token information
     */
    function getPersonaToken(uint256 tokenId) external view returns (PersonaToken memory) {
        require(personaTokens[tokenId].isActive, "Token not active");
        return personaTokens[tokenId];
    }

    /**
     * @dev Get all tokens owned by a user
     */
    function getUserTokens(address user) external view returns (uint256[] memory) {
        return userTokens[user];
    }

    /**
     * @dev Get all tokens in a persona group
     */
    function getGroupTokens(uint256 groupId) external view returns (uint256[] memory) {
        require(personaGroups[groupId].isActive, "Group not active");
        return personaGroups[groupId].tokenIds;
    }

    /**
     * @dev Check if user can access agent for a token
     */
    function canAccessAgent(address user, uint256 tokenId) external view returns (bool) {
        return ownerOf(tokenId) == user && personaTokens[tokenId].isActive;
    }

    /**
     * @dev Deactivate a token (only group admin)
     */
    function deactivateToken(uint256 tokenId) external {
        PersonaToken storage token = personaTokens[tokenId];
        PersonaGroup storage group = personaGroups[token.groupId];
        require(group.admin == msg.sender, "Not group admin");

        token.isActive = false;
    }

    /**
     * @dev Deactivate a group (only group admin)
     */
    function deactivateGroup(uint256 groupId) external {
        PersonaGroup storage group = personaGroups[groupId];
        require(group.admin == msg.sender, "Not group admin");

        group.isActive = false;
    }

    /**
     * @dev Update 0G infrastructure addresses (only admin)
     */
    function updateInfrastructure(address newOgStorage, address newOgCompute) external onlyRole(ADMIN_ROLE) {
        ogStorageAddress = newOgStorage;
        ogComputeAddress = newOgCompute;
    }

    // Internal functions

    /**
     * @dev Process agent query (placeholder for 0G Compute integration)
     */
    function _processAgentQuery(
        uint256 tokenId,
        string memory, /* encryptedDataURI */
        string memory personalityTraits,
        string memory query
    ) internal pure returns (string memory) {
        // This is a placeholder. In real implementation:
        // 1. Call 0G Compute with encrypted data URI
        // 2. Include personality traits and token context
        // 3. Process user query with AI agent
        // 4. Return personalized response

        return string(
            abi.encodePacked(
                "Agent response for token ",
                Strings.toString(tokenId),
                " with traits: ",
                personalityTraits,
                " responding to: ",
                query
            )
        );
    }

    /**
     * @dev Remove token from user's token list
     */
    function _removeFromUserTokens(address user, uint256 tokenId) internal {
        uint256[] storage tokens = userTokens[user];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    /**
     * @dev Override tokenURI to provide metadata
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        PersonaToken storage token = personaTokens[tokenId];
        PersonaGroup storage group = personaGroups[token.groupId];

        // Return JSON metadata
        return string(
            abi.encodePacked(
                '{"name":"',
                group.name,
                " #",
                Strings.toString(tokenId),
                '","description":"',
                group.description,
                '","attributes":[',
                '{"trait_type":"Group","value":"',
                group.name,
                '"},',
                '{"trait_type":"Personality","value":"',
                token.personalityTraits,
                '"},',
                '{"trait_type":"Minted","value":"',
                Strings.toString(token.mintedAt),
                '"},',
                '{"trait_type":"Last Interaction","value":"',
                Strings.toString(token.lastInteraction),
                '"}',
                "]}"
            )
        );
    }

    /**
     * @dev Support interface detection
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
