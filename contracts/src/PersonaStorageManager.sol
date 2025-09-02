// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PersonaStorageManager
 * @dev Manages centralized encrypted storage for persona data
 *
 * Key Features:
 * - Admin-controlled encrypted data storage
 * - No data access transfer with NFT ownership
 * - Integration with 0G Storage for decentralized storage
 * - Group-based data management
 */
contract PersonaStorageManager is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant STORAGE_ADMIN_ROLE = keccak256("STORAGE_ADMIN_ROLE");

    struct StorageGroup {
        string name;
        address admin;
        bytes32 encryptionKeyHash; // Hash of the encryption key (not the key itself)
        string storageURI; // 0G Storage URI
        bytes32 dataHash; // Hash of encrypted data
        uint256 lastUpdated;
        uint256 version;
        bool isActive;
        mapping(address => bool) authorizedUpdaters;
    }

    struct DataUpdate {
        uint256 groupId;
        string newStorageURI;
        bytes32 newDataHash;
        uint256 timestamp;
        address updater;
        string updateReason;
    }

    // Storage
    mapping(uint256 => StorageGroup) private storageGroups;
    mapping(uint256 => DataUpdate[]) private updateHistory;
    mapping(bytes32 => uint256) private keyHashToGroupId;

    uint256 private _nextGroupId = 1;

    // 0G Infrastructure
    address public ogStorageAddress;
    string public centralServerPublicKey; // Public key for encryption

    // Events
    event StorageGroupCreated(uint256 indexed groupId, address indexed admin, string name, bytes32 encryptionKeyHash);

    event DataUpdated(
        uint256 indexed groupId, string newStorageURI, bytes32 newDataHash, uint256 version, address updater
    );

    event AuthorizedUpdaterAdded(uint256 indexed groupId, address indexed updater);

    event AuthorizedUpdaterRemoved(uint256 indexed groupId, address indexed updater);

    event CentralServerKeyUpdated(string oldKey, string newKey);

    constructor(address _ogStorageAddress, string memory _centralServerPublicKey) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(STORAGE_ADMIN_ROLE, msg.sender);

        ogStorageAddress = _ogStorageAddress;
        centralServerPublicKey = _centralServerPublicKey;
    }

    /**
     * @dev Create a new storage group for persona data
     * @param name Name of the storage group
     * @param encryptionKeyHash Hash of the encryption key used
     * @param initialStorageURI Initial 0G Storage URI
     * @param initialDataHash Hash of initial encrypted data
     */
    function createStorageGroup(
        string memory name,
        bytes32 encryptionKeyHash,
        string memory initialStorageURI,
        bytes32 initialDataHash
    ) external returns (uint256 groupId) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(encryptionKeyHash != bytes32(0), "Invalid key hash");
        require(bytes(initialStorageURI).length > 0, "Storage URI cannot be empty");
        require(keyHashToGroupId[encryptionKeyHash] == 0, "Key hash already used");

        groupId = _nextGroupId++;

        StorageGroup storage group = storageGroups[groupId];
        group.name = name;
        group.admin = msg.sender;
        group.encryptionKeyHash = encryptionKeyHash;
        group.storageURI = initialStorageURI;
        group.dataHash = initialDataHash;
        group.lastUpdated = block.timestamp;
        group.version = 1;
        group.isActive = true;
        group.authorizedUpdaters[msg.sender] = true;

        keyHashToGroupId[encryptionKeyHash] = groupId;

        // Record initial update
        updateHistory[groupId].push(
            DataUpdate({
                groupId: groupId,
                newStorageURI: initialStorageURI,
                newDataHash: initialDataHash,
                timestamp: block.timestamp,
                updater: msg.sender,
                updateReason: "Initial creation"
            })
        );

        emit StorageGroupCreated(groupId, msg.sender, name, encryptionKeyHash);
    }

    /**
     * @dev Update persona data in a storage group
     * @param groupId ID of the storage group
     * @param newStorageURI New 0G Storage URI
     * @param newDataHash Hash of new encrypted data
     * @param updateReason Reason for the update
     */
    function updatePersonaData(
        uint256 groupId,
        string memory newStorageURI,
        bytes32 newDataHash,
        string memory updateReason
    ) external nonReentrant {
        StorageGroup storage group = storageGroups[groupId];
        require(group.isActive, "Group not active");
        require(group.admin == msg.sender || group.authorizedUpdaters[msg.sender], "Not authorized to update");
        require(bytes(newStorageURI).length > 0, "Storage URI cannot be empty");
        require(newDataHash != bytes32(0), "Invalid data hash");

        // Update group data
        group.storageURI = newStorageURI;
        group.dataHash = newDataHash;
        group.lastUpdated = block.timestamp;
        group.version++;

        // Record update in history
        updateHistory[groupId].push(
            DataUpdate({
                groupId: groupId,
                newStorageURI: newStorageURI,
                newDataHash: newDataHash,
                timestamp: block.timestamp,
                updater: msg.sender,
                updateReason: updateReason
            })
        );

        emit DataUpdated(groupId, newStorageURI, newDataHash, group.version, msg.sender);
    }

    /**
     * @dev Add authorized updater to a storage group
     * @param groupId ID of the storage group
     * @param updater Address to authorize
     */
    function addAuthorizedUpdater(uint256 groupId, address updater) external {
        StorageGroup storage group = storageGroups[groupId];
        require(group.isActive, "Group not active");
        require(group.admin == msg.sender, "Not group admin");
        require(updater != address(0), "Invalid updater address");

        group.authorizedUpdaters[updater] = true;
        emit AuthorizedUpdaterAdded(groupId, updater);
    }

    /**
     * @dev Remove authorized updater from a storage group
     * @param groupId ID of the storage group
     * @param updater Address to remove authorization
     */
    function removeAuthorizedUpdater(uint256 groupId, address updater) external {
        StorageGroup storage group = storageGroups[groupId];
        require(group.isActive, "Group not active");
        require(group.admin == msg.sender, "Not group admin");

        group.authorizedUpdaters[updater] = false;
        emit AuthorizedUpdaterRemoved(groupId, updater);
    }

    /**
     * @dev Get storage group information (public data only)
     * @param groupId ID of the storage group
     */
    function getStorageGroupInfo(uint256 groupId)
        external
        view
        returns (
            string memory name,
            address admin,
            string memory storageURI,
            bytes32 dataHash,
            uint256 lastUpdated,
            uint256 version,
            bool isActive
        )
    {
        StorageGroup storage group = storageGroups[groupId];
        require(group.isActive, "Group not active");

        return (
            group.name, group.admin, group.storageURI, group.dataHash, group.lastUpdated, group.version, group.isActive
        );
    }

    /**
     * @dev Get update history for a storage group
     * @param groupId ID of the storage group
     * @param limit Maximum number of updates to return (0 for all)
     */
    function getUpdateHistory(uint256 groupId, uint256 limit) external view returns (DataUpdate[] memory updates) {
        require(storageGroups[groupId].isActive, "Group not active");

        DataUpdate[] storage history = updateHistory[groupId];
        uint256 length = history.length;

        if (limit == 0 || limit > length) {
            limit = length;
        }

        updates = new DataUpdate[](limit);

        // Return most recent updates first
        for (uint256 i = 0; i < limit; i++) {
            updates[i] = history[length - 1 - i];
        }
    }

    /**
     * @dev Check if address is authorized to update a group
     * @param groupId ID of the storage group
     * @param updater Address to check
     */
    function isAuthorizedUpdater(uint256 groupId, address updater) external view returns (bool) {
        StorageGroup storage group = storageGroups[groupId];
        return group.isActive && (group.admin == updater || group.authorizedUpdaters[updater]);
    }

    /**
     * @dev Get group ID by encryption key hash
     * @param keyHash Hash of encryption key
     */
    function getGroupIdByKeyHash(bytes32 keyHash) external view returns (uint256) {
        return keyHashToGroupId[keyHash];
    }

    /**
     * @dev Deactivate a storage group (only group admin)
     * @param groupId ID of the storage group
     */
    function deactivateStorageGroup(uint256 groupId) external {
        StorageGroup storage group = storageGroups[groupId];
        require(group.admin == msg.sender, "Not group admin");

        group.isActive = false;
    }

    /**
     * @dev Transfer group admin role (only current admin)
     * @param groupId ID of the storage group
     * @param newAdmin New admin address
     */
    function transferGroupAdmin(uint256 groupId, address newAdmin) external {
        StorageGroup storage group = storageGroups[groupId];
        require(group.isActive, "Group not active");
        require(group.admin == msg.sender, "Not group admin");
        require(newAdmin != address(0), "Invalid new admin");

        address oldAdmin = group.admin;
        group.admin = newAdmin;

        // Remove old admin from authorized updaters and add new admin
        group.authorizedUpdaters[oldAdmin] = false;
        group.authorizedUpdaters[newAdmin] = true;
    }

    /**
     * @dev Update central server public key (only admin)
     * @param newPublicKey New public key for encryption
     */
    function updateCentralServerKey(string memory newPublicKey) external onlyRole(ADMIN_ROLE) {
        require(bytes(newPublicKey).length > 0, "Invalid public key");

        string memory oldKey = centralServerPublicKey;
        centralServerPublicKey = newPublicKey;

        emit CentralServerKeyUpdated(oldKey, newPublicKey);
    }

    /**
     * @dev Update 0G Storage address (only admin)
     * @param newStorageAddress New 0G Storage address
     */
    function updateOGStorageAddress(address newStorageAddress) external onlyRole(ADMIN_ROLE) {
        require(newStorageAddress != address(0), "Invalid storage address");
        ogStorageAddress = newStorageAddress;
    }

    /**
     * @dev Get central server public key
     */
    function getCentralServerPublicKey() external view returns (string memory) {
        return centralServerPublicKey;
    }

    /**
     * @dev Get total number of storage groups
     */
    function getTotalGroups() external view returns (uint256) {
        return _nextGroupId - 1;
    }
}
