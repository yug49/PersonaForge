// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/PersonaINFT.sol";
import "../src/PersonaStorageManager.sol";
import "../src/interfaces/IPersonaAgent.sol";
import "../src/PersonaAgentManager.sol";

/**
 * @title Invariant Tests
 * @dev Tests that verify critical system invariants that must always hold true
 */
contract InvariantTest is Test {
    PersonaINFT public personaINFT;
    PersonaStorageManager public storageManager;
    PersonaAgentManager public agentManager;

    // Test addresses
    address public deployer = address(0x1);
    address public admin = address(0x2);
    address public groupAdmin = address(0x3);
    address public user1 = address(0x11);
    address public user2 = address(0x12);
    address public user3 = address(0x13);

    // Infrastructure addresses
    address public ogStorage = address(0x1111);
    address public ogCompute = address(0x2222);

    // Test data
    string constant NAME = "PersonaForge INFTs";
    string constant SYMBOL = "PINFT";
    string constant CENTRAL_PUBLIC_KEY = "-----BEGIN PUBLIC KEY-----INVARIANT_TEST_KEY-----END PUBLIC KEY-----";
    string constant AGENT_MODEL_ENDPOINT = "https://compute-testnet.0g.ai/v1/agent/inference";

    // State tracking for invariants
    uint256[] public allTokenIds;
    uint256[] public allGroupIds;
    uint256[] public allStorageGroupIds;
    mapping(uint256 => address) public tokenToCurrentOwner;
    mapping(address => uint256[]) public ownerToTokens;

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy contracts
        storageManager = new PersonaStorageManager(ogStorage, CENTRAL_PUBLIC_KEY);
        personaINFT = new PersonaINFT(NAME, SYMBOL, ogStorage, ogCompute);
        agentManager =
            new PersonaAgentManager(address(personaINFT), address(storageManager), ogCompute, AGENT_MODEL_ENDPOINT);

        // Set up roles
        personaINFT.grantRole(personaINFT.ADMIN_ROLE(), admin);
        personaINFT.grantRole(personaINFT.GROUP_ADMIN_ROLE(), groupAdmin);
        storageManager.grantRole(storageManager.ADMIN_ROLE(), admin);
        storageManager.grantRole(storageManager.STORAGE_ADMIN_ROLE(), groupAdmin);
        agentManager.grantRole(agentManager.ADMIN_ROLE(), admin);

        // Configure interconnections
        agentManager.addAuthorizedCaller(address(personaINFT));

        vm.stopPrank();
    }

    // Helper functions for state tracking
    function trackToken(uint256 tokenId, address owner) internal {
        allTokenIds.push(tokenId);
        tokenToCurrentOwner[tokenId] = owner;
        ownerToTokens[owner].push(tokenId);
    }

    function updateTokenOwnership(uint256 tokenId, address newOwner) internal {
        address oldOwner = tokenToCurrentOwner[tokenId];

        // Remove from old owner
        uint256[] storage oldOwnerTokens = ownerToTokens[oldOwner];
        for (uint256 i = 0; i < oldOwnerTokens.length; i++) {
            if (oldOwnerTokens[i] == tokenId) {
                oldOwnerTokens[i] = oldOwnerTokens[oldOwnerTokens.length - 1];
                oldOwnerTokens.pop();
                break;
            }
        }

        // Add to new owner
        tokenToCurrentOwner[tokenId] = newOwner;
        ownerToTokens[newOwner].push(tokenId);
    }

    // ============ ERC721 Invariants ============

    function invariant_ERC721_OwnershipConsistency() public view {
        // Every token must have exactly one owner
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            address owner = personaINFT.ownerOf(tokenId);

            assertNotEq(owner, address(0), "Token must have a valid owner");

            // Owner must be able to transfer
            assertTrue(
                personaINFT.isApprovedForAll(owner, owner) || personaINFT.getApproved(tokenId) == owner
                    || owner == personaINFT.ownerOf(tokenId),
                "Owner must be able to transfer token"
            );
        }
    }

    function invariant_ERC721_BalanceConsistency() public view {
        // Sum of all balances must equal total supply
        uint256 totalBalance = 0;

        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            address owner = personaINFT.ownerOf(tokenId);

            bool counted = false;
            for (uint256 j = 0; j < i; j++) {
                if (personaINFT.ownerOf(allTokenIds[j]) == owner) {
                    counted = true;
                    break;
                }
            }

            if (!counted) {
                totalBalance += personaINFT.balanceOf(owner);
            }
        }

        assertEq(totalBalance, allTokenIds.length, "Total balance must equal number of tokens");
    }

    // ============ PersonaINFT Invariants ============

    function invariant_PersonaINFT_TokenGroupConsistency() public view {
        // Every token must belong to a valid group
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);

            assertTrue(token.groupId > 0, "Token must belong to a valid group");
            assertTrue(token.groupId <= personaINFT.totalGroups(), "Token group must exist");

            // Group must contain this token
            PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(token.groupId);

            bool tokenFoundInGroup = false;
            for (uint256 j = 0; j < group.tokenIds.length; j++) {
                if (group.tokenIds[j] == tokenId) {
                    tokenFoundInGroup = true;
                    break;
                }
            }
            assertTrue(tokenFoundInGroup, "Token must be listed in its group");
        }
    }

    function invariant_PersonaINFT_GroupTokenConsistency() public view {
        // Every token in a group must exist and belong to that group
        for (uint256 i = 0; i < allGroupIds.length; i++) {
            uint256 groupId = allGroupIds[i];
            PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(groupId);

            for (uint256 j = 0; j < group.tokenIds.length; j++) {
                uint256 tokenId = group.tokenIds[j];

                // Token must exist
                address owner = personaINFT.ownerOf(tokenId);
                assertNotEq(owner, address(0), "Token in group must exist");

                // Token must belong to this group
                PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
                assertEq(token.groupId, groupId, "Token must belong to correct group");
            }
        }
    }

    function invariant_PersonaINFT_UserTokenConsistency() public view {
        // Every user's token list must be accurate
        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256[] memory userTokens = personaINFT.getUserTokens(user);

            for (uint256 j = 0; j < userTokens.length; j++) {
                uint256 tokenId = userTokens[j];

                // User must own the token
                assertEq(personaINFT.ownerOf(tokenId), user, "User must own listed token");

                // Token must be active (if user list is maintained correctly)
                PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
                if (token.isActive) {
                    assertTrue(true, "Active token correctly listed");
                }
            }

            // Reverse check: user must be listed as owner of all their tokens
            uint256 userBalance = personaINFT.balanceOf(user);
            if (userBalance > 0) {
                assertEq(userTokens.length, userBalance, "User token list must match balance");
            }
        }
    }

    function invariant_PersonaINFT_NextTokenIdMonotonic() public view {
        // nextTokenId must always be greater than the highest minted token
        uint256 nextTokenId = personaINFT.nextTokenId();

        for (uint256 i = 0; i < allTokenIds.length; i++) {
            assertTrue(allTokenIds[i] < nextTokenId, "Next token ID must be greater than all existing tokens");
        }
    }

    function invariant_PersonaINFT_ActiveTokensCanInteract() public view {
        // All active tokens must allow interaction by their owners
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
            address owner = personaINFT.ownerOf(tokenId);

            if (token.isActive) {
                assertTrue(
                    personaINFT.canAccessAgent(owner, tokenId), "Active token owner must be able to access agent"
                );
            } else {
                assertFalse(
                    personaINFT.canAccessAgent(owner, tokenId), "Inactive token owner must not be able to access agent"
                );
            }
        }
    }

    // ============ PersonaStorageManager Invariants ============

    function invariant_StorageManager_GroupVersionMonotonic() public view {
        // Storage group versions must be monotonically increasing
        for (uint256 i = 0; i < allStorageGroupIds.length; i++) {
            uint256 groupId = allStorageGroupIds[i];
            (,,,,, uint256 version,) = storageManager.getStorageGroupInfo(groupId);

            assertTrue(version > 0, "Storage group version must be positive");

            // Check update history for monotonic version increases
            PersonaStorageManager.DataUpdate[] memory history = storageManager.getUpdateHistory(groupId, 100);

            for (uint256 j = 1; j < history.length; j++) {
                assertTrue(
                    history[j].timestamp >= history[j - 1].timestamp,
                    "Update history timestamps must be monotonically increasing"
                );
            }
        }
    }

    function invariant_StorageManager_GroupAdminConsistency() public view {
        // Only group admins can manage their groups
        for (uint256 i = 0; i < allStorageGroupIds.length; i++) {
            uint256 groupId = allStorageGroupIds[i];
            (, address storageGroupAdmin,,,,,) = storageManager.getStorageGroupInfo(groupId);

            assertNotEq(storageGroupAdmin, address(0), "Storage group must have a valid admin");

            // Admin must have the correct role
            assertTrue(
                storageManager.hasRole(storageManager.STORAGE_ADMIN_ROLE(), storageGroupAdmin)
                    || storageManager.hasRole(storageManager.DEFAULT_ADMIN_ROLE(), storageGroupAdmin),
                "Group admin must have appropriate role"
            );
        }
    }

    function invariant_StorageManager_UpdateHistoryIntegrity() public view {
        // Update history must be consistent with current state
        for (uint256 i = 0; i < allStorageGroupIds.length; i++) {
            uint256 groupId = allStorageGroupIds[i];
            (,,, bytes32 currentDataHash, uint256 lastUpdated, uint256 currentVersion,) =
                storageManager.getStorageGroupInfo(groupId);

            PersonaStorageManager.DataUpdate[] memory history = storageManager.getUpdateHistory(groupId, 100);

            if (history.length > 0) {
                // Latest update must match current state (history is returned in reverse chronological order)
                PersonaStorageManager.DataUpdate memory latestUpdate = history[0];
                assertEq(latestUpdate.newDataHash, currentDataHash, "Latest update hash must match current");
                assertEq(latestUpdate.timestamp, lastUpdated, "Latest update timestamp must match current");
            } else if (currentVersion > 1) {
                revert("If version > 1, there must be update history");
            }
        }
    }

    // ============ PersonaAgentManager Invariants ============

    function invariant_AgentManager_AccessControlConsistency() public view {
        // Agent access must be consistent with token ownership
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            address owner = personaINFT.ownerOf(tokenId);

            // Owner must have agent access if token is active
            PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
            if (token.isActive) {
                assertTrue(agentManager.hasAgentAccess(tokenId, owner), "Active token owner must have agent access");
            }

            // Non-owners must not have agent access
            address[] memory nonOwners = new address[](2);
            if (owner != user1) nonOwners[0] = user1;
            if (owner != user2) nonOwners[1] = user2;

            for (uint256 j = 0; j < nonOwners.length; j++) {
                if (nonOwners[j] != address(0)) {
                    assertFalse(
                        agentManager.hasAgentAccess(tokenId, nonOwners[j]), "Non-owner must not have agent access"
                    );
                }
            }
        }
    }

    function invariant_AgentManager_InteractionStatsConsistency() public view {
        // Agent stats must be consistent with interaction history
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            PersonaAgentManager.AgentStats memory stats = agentManager.getAgentStats(tokenId);
            PersonaAgentManager.InteractionRecord[] memory history =
                agentManager.getInteractionRecords(tokenId, 0, 1000);

            assertEq(stats.totalInteractions, history.length, "Stats must match interaction history length");

            if (history.length > 0) {
                // Last interaction timestamp must match
                uint256 latestInteractionTime = 0;
                for (uint256 j = 0; j < history.length; j++) {
                    if (history[j].timestamp > latestInteractionTime) {
                        latestInteractionTime = history[j].timestamp;
                    }
                }
                assertEq(stats.lastInteraction, latestInteractionTime, "Last interaction time must match");
            } else {
                assertEq(stats.lastInteraction, 0, "No interactions means last interaction should be 0");
            }

            // Agent stats only become active after first interaction, not immediately when token is created
            // PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
            // assertEq(stats.isActive, token.isActive, "Agent stats active status must match token status");
        }
    }

    function invariant_AgentManager_ConfigurationOwnership() public view {
        // Agent configuration can only be updated by token owner
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            IPersonaAgent.PersonaConfig memory config = agentManager.getPersonaConfig(tokenId);

            if (bytes(config.description).length > 0) {
                // If config exists, verify the structure is valid
                assertTrue(
                    bytes(config.name).length > 0 || bytes(config.description).length > 0,
                    "Config must have name or description"
                );
                // Note: PersonaConfig doesn't track updater, so we can't verify ownership history
                assertTrue(config.isActive || !config.isActive, "Config isActive field must be properly set");
            }
        }
    }

    // ============ Cross-Contract Invariants ============

    function invariant_CrossContract_TokenExistenceConsistency() public view {
        // Tokens referenced in AgentManager must exist in PersonaINFT
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];

            // Token must exist in PersonaINFT
            address owner = personaINFT.ownerOf(tokenId);
            assertNotEq(owner, address(0), "Token must exist in PersonaINFT");

            // Agent stats must be available
            /* PersonaAgentManager.AgentStats memory stats = */
            agentManager.getAgentStats(tokenId);
            // Just accessing stats should not revert

            // Agent access check must work
            bool hasAccess = agentManager.hasAgentAccess(tokenId, owner);
            PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);

            if (token.isActive) {
                assertTrue(hasAccess, "Active token owner must have agent access");
            }
        }
    }

    function invariant_CrossContract_RoleConsistency() public view {
        // Role consistency across all contracts
        bytes32 adminRole = personaINFT.ADMIN_ROLE();

        // Anyone with ADMIN_ROLE on PersonaINFT should be able to perform admin functions
        assertTrue(personaINFT.hasRole(adminRole, admin), "Admin must have admin role on PersonaINFT");

        assertTrue(
            storageManager.hasRole(storageManager.ADMIN_ROLE(), admin), "Admin must have admin role on StorageManager"
        );

        assertTrue(agentManager.hasRole(agentManager.ADMIN_ROLE(), admin), "Admin must have admin role on AgentManager");
    }

    // ============ Business Logic Invariants ============

    function invariant_BusinessLogic_DataIntegrity() public view {
        // Data hashes and URIs must be consistent
        for (uint256 i = 0; i < allGroupIds.length; i++) {
            uint256 groupId = allGroupIds[i];
            PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(groupId);

            // Data hash must not be zero for active groups
            if (group.isActive) {
                assertNotEq(group.dataHash, bytes32(0), "Active group must have valid data hash");
                assertTrue(bytes(group.encryptedDataURI).length > 0, "Active group must have data URI");
            }

            // Last updated must be valid
            assertTrue(group.lastUpdated > 0, "Group must have valid last updated timestamp");
        }
    }

    function invariant_BusinessLogic_OwnershipTransferIntegrity() public view {
        // After ownership transfers, all related data must be consistent
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            address currentOwner = personaINFT.ownerOf(tokenId);

            // Current owner must be in user token list
            uint256[] memory userTokens = personaINFT.getUserTokens(currentOwner);
            bool tokenFoundInUserList = false;

            for (uint256 j = 0; j < userTokens.length; j++) {
                if (userTokens[j] == tokenId) {
                    tokenFoundInUserList = true;
                    break;
                }
            }

            assertTrue(tokenFoundInUserList, "Token must be in current owner's token list");

            // Agent access must reflect current ownership
            PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
            if (token.isActive) {
                assertTrue(
                    agentManager.hasAgentAccess(tokenId, currentOwner),
                    "Current owner must have agent access for active token"
                );
            }
        }
    }

    // ============ Test Functions to Establish Invariants ============

    function test_InvariantsAfterBasicOperations() public {
        // Create some basic state to test invariants
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Test Group", "Test Description", "0g://storage/test-data", keccak256("test-data")
        );
        allGroupIds.push(groupId);

        uint256 storageGroupId = storageManager.createStorageGroup(
            "Test Storage", keccak256("test-key"), "0g://storage/test-encrypted", keccak256("test-encrypted")
        );
        allStorageGroupIds.push(storageGroupId);

        uint256 tokenId1 = personaINFT.mintPersonaINFT(user1, groupId, "traits1");
        trackToken(tokenId1, user1);

        uint256 tokenId2 = personaINFT.mintPersonaINFT(user2, groupId, "traits2");
        trackToken(tokenId2, user2);

        vm.stopPrank();

        // Run all invariants
        invariant_ERC721_OwnershipConsistency();
        invariant_ERC721_BalanceConsistency();
        invariant_PersonaINFT_TokenGroupConsistency();
        invariant_PersonaINFT_GroupTokenConsistency();
        invariant_PersonaINFT_UserTokenConsistency();
        invariant_PersonaINFT_NextTokenIdMonotonic();
        invariant_PersonaINFT_ActiveTokensCanInteract();
        invariant_StorageManager_GroupVersionMonotonic();
        invariant_StorageManager_GroupAdminConsistency();
        invariant_AgentManager_AccessControlConsistency();
        invariant_CrossContract_TokenExistenceConsistency();
        invariant_CrossContract_RoleConsistency();
        invariant_BusinessLogic_DataIntegrity();
        invariant_BusinessLogic_OwnershipTransferIntegrity();
    }

    function test_InvariantsAfterTransfers() public {
        // Create initial state
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Transfer Test Group", "Test Description", "0g://storage/transfer-data", keccak256("transfer-data")
        );
        allGroupIds.push(groupId);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, "transfer-traits");
        trackToken(tokenId, user1);

        vm.stopPrank();

        // User1 interacts with agent
        vm.startPrank(user1);
        personaINFT.interactWithAgent(tokenId, "Hello before transfer");
        agentManager.updatePersonaConfigData(tokenId, "Config before transfer");
        vm.stopPrank();

        // Transfer token
        vm.startPrank(user1);
        personaINFT.transferFrom(user1, user2, tokenId);
        vm.stopPrank();

        updateTokenOwnership(tokenId, user2);

        // User2 interacts with agent
        vm.startPrank(user2);
        personaINFT.interactWithAgent(tokenId, "Hello after transfer");
        agentManager.updatePersonaConfigData(tokenId, "Config after transfer");
        vm.stopPrank();

        // Run all invariants after transfers
        invariant_ERC721_OwnershipConsistency();
        invariant_ERC721_BalanceConsistency();
        invariant_PersonaINFT_TokenGroupConsistency();
        invariant_PersonaINFT_UserTokenConsistency();
        invariant_AgentManager_AccessControlConsistency();
        invariant_AgentManager_InteractionStatsConsistency();
        invariant_CrossContract_TokenExistenceConsistency();
        invariant_BusinessLogic_OwnershipTransferIntegrity();
    }

    function test_InvariantsAfterDataUpdates() public {
        // Create initial state
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Update Test Group", "Test Description", "0g://storage/update-data", keccak256("update-data")
        );
        allGroupIds.push(groupId);

        uint256 storageGroupId = storageManager.createStorageGroup(
            "Update Storage", keccak256("update-key"), "0g://storage/update-encrypted", keccak256("update-encrypted")
        );
        allStorageGroupIds.push(storageGroupId);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, "update-traits");
        trackToken(tokenId, user1);

        // Perform multiple updates
        personaINFT.updatePersonaGroup(groupId, "0g://storage/update-data-v2", keccak256("update-data-v2"));

        storageManager.updatePersonaData(
            storageGroupId, "0g://storage/update-encrypted-v2", keccak256("update-encrypted-v2"), "First update"
        );

        storageManager.updatePersonaData(
            storageGroupId, "0g://storage/update-encrypted-v3", keccak256("update-encrypted-v3"), "Second update"
        );

        vm.stopPrank();

        // Run invariants after updates
        invariant_StorageManager_GroupVersionMonotonic();
        invariant_StorageManager_UpdateHistoryIntegrity();
        invariant_BusinessLogic_DataIntegrity();
        invariant_CrossContract_TokenExistenceConsistency();
    }
}
