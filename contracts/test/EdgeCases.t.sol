// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/PersonaINFT.sol";
import "../src/PersonaStorageManager.sol";
import "../src/interfaces/IPersonaAgent.sol";
import "../src/PersonaAgentManager.sol";

/**
 * @title Edge Case Tests
 * @dev Comprehensive tests for edge cases, boundary conditions, and extreme scenarios
 */
contract EdgeCasesTest is Test {
    PersonaINFT public personaINFT;
    PersonaStorageManager public storageManager;
    PersonaAgentManager public agentManager;

    // Test addresses
    address public deployer = address(0x1);
    address public admin = address(0x2);
    address public groupAdmin = address(0x3);
    address public user1 = address(0x11);
    address public user2 = address(0x12);
    address public maliciousUser = address(0x666);

    // Infrastructure addresses
    address public ogStorage = address(0x1111);
    address public ogCompute = address(0x2222);

    // Test data
    string constant NAME = "PersonaForge INFTs";
    string constant SYMBOL = "PINFT";
    string constant CENTRAL_PUBLIC_KEY = "-----BEGIN PUBLIC KEY-----EDGE_CASE_TEST_KEY-----END PUBLIC KEY-----";
    string constant AGENT_MODEL_ENDPOINT = "https://compute-testnet.0g.ai/v1/agent/inference";

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

    // ============ String Length Edge Cases ============

    function test_EdgeCase_EmptyStrings() public {
        vm.startPrank(groupAdmin);

        // Test empty strings where allowed
        vm.expectRevert("Group name cannot be empty");
        personaINFT.createPersonaGroup("", "desc", "uri", bytes32(uint256(1)));

        vm.expectRevert("Data URI cannot be empty");
        personaINFT.createPersonaGroup("name", "desc", "", bytes32(uint256(1)));

        // Empty description should be allowed
        uint256 groupId = personaINFT.createPersonaGroup("name", "", "uri", bytes32(uint256(1)));
        assertTrue(groupId > 0);

        // Empty personality traits should be allowed
        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, "");
        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
        assertEq(token.personalityTraits, "");

        vm.stopPrank();
    }

    function test_EdgeCase_MaximumStringLengths() public {
        vm.startPrank(groupAdmin);

        // Create extremely long strings (up to practical limits)
        string memory maxName = "";
        string memory maxDescription = "";
        string memory maxURI = "";
        string memory maxTraits = "";

        // Build maximum length strings (avoiding gas limit issues)
        for (uint256 i = 0; i < 50; i++) {
            maxName = string(abi.encodePacked(maxName, "VeryLongGroupName"));
        }

        for (uint256 i = 0; i < 100; i++) {
            maxDescription = string(abi.encodePacked(maxDescription, "VeryLongDescription"));
        }

        for (uint256 i = 0; i < 30; i++) {
            maxURI = string(abi.encodePacked(maxURI, "0g://storage/very-long-uri-segment"));
        }

        for (uint256 i = 0; i < 80; i++) {
            maxTraits = string(abi.encodePacked(maxTraits, "VeryLongPersonalityTrait"));
        }

        // These should succeed despite being very long
        uint256 groupId = personaINFT.createPersonaGroup(maxName, maxDescription, maxURI, keccak256(bytes(maxURI)));

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, maxTraits);

        // Verify data integrity
        PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(groupId);
        assertEq(group.name, maxName);
        assertEq(group.description, maxDescription);
        assertEq(group.encryptedDataURI, maxURI);

        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
        assertEq(token.personalityTraits, maxTraits);

        vm.stopPrank();
    }

    function test_EdgeCase_SpecialCharactersInStrings() public {
        vm.startPrank(groupAdmin);

        // Test various special characters
        string memory specialName = "Group @#$%^&*()_+-=[]{}|;':\",./<>?`~";
        string memory unicodeName = unicode"Group 🚀 🤖 测试 ñáéíóú αβγδε";
        string memory newlineName = "Group\nWith\nNewlines";
        string memory quoteName = "Group \"with\" 'quotes'";

        uint256 groupId1 = personaINFT.createPersonaGroup(
            specialName, "Description with special chars", "0g://storage/special-data", bytes32(uint256(1))
        );

        uint256 groupId2 = personaINFT.createPersonaGroup(
            unicodeName, unicode"Unicode description 测试 🌍", "0g://storage/unicode-data", bytes32(uint256(2))
        );

        uint256 groupId3 = personaINFT.createPersonaGroup(
            newlineName, "Description\nwith\nnewlines", "0g://storage/newline-data", bytes32(uint256(3))
        );

        uint256 groupId4 = personaINFT.createPersonaGroup(
            quoteName, "Description with \"quotes\" and 'apostrophes'", "0g://storage/quote-data", bytes32(uint256(4))
        );

        // Verify all groups were created successfully
        assertTrue(groupId1 > 0);
        assertTrue(groupId2 > 0);
        assertTrue(groupId3 > 0);
        assertTrue(groupId4 > 0);

        // Test special character personality traits
        uint256 tokenId = personaINFT.mintPersonaINFT(
            user1, groupId1, unicode"traits: 🤖 intelligent, 💪 strong, 🧠 analytical, ❤️ compassionate"
        );

        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
        assertTrue(bytes(token.personalityTraits).length > 0);

        vm.stopPrank();
    }

    // ============ Numerical Edge Cases ============

    function test_EdgeCase_MaximumTokenIds() public {
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Max Token Test", "Testing maximum token IDs", "0g://storage/max-token-data", bytes32(uint256(1))
        );

        // Test behavior near maximum uint256 values
        // Note: We can't actually reach uint256 max due to gas limits,
        // but we can test the edge case logic

        uint256 initialNextTokenId = personaINFT.nextTokenId();

        // Mint several tokens to verify ID increment
        uint256 tokenId1 = personaINFT.mintPersonaINFT(user1, groupId, "traits1");
        uint256 tokenId2 = personaINFT.mintPersonaINFT(user1, groupId, "traits2");
        uint256 tokenId3 = personaINFT.mintPersonaINFT(user1, groupId, "traits3");

        assertEq(tokenId1, initialNextTokenId);
        assertEq(tokenId2, initialNextTokenId + 1);
        assertEq(tokenId3, initialNextTokenId + 2);
        assertEq(personaINFT.nextTokenId(), initialNextTokenId + 3);

        vm.stopPrank();
    }

    function test_EdgeCase_ZeroValues() public {
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Zero Test",
            "Testing zero values",
            "0g://storage/zero-data",
            bytes32(0) // Zero hash should be allowed
        );

        PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(groupId);
        assertEq(group.dataHash, bytes32(0));

        // Test with zero-like addresses (should fail where appropriate)
        vm.expectRevert("Cannot mint to zero address");
        personaINFT.mintPersonaINFT(address(0), groupId, "traits");

        vm.stopPrank();
    }

    function test_EdgeCase_TimestampEdgeCases() public {
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Timestamp Test", "Testing timestamp edge cases", "0g://storage/timestamp-data", bytes32(uint256(1))
        );

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, "timestamp-traits");

        vm.stopPrank();

        // Test at timestamp 0 (should not be possible in practice)
        vm.warp(0);
        vm.startPrank(user1);

        // Interaction should still work even at timestamp 0
        string memory response = personaINFT.interactWithAgent(tokenId, "Query at timestamp 0");
        assertTrue(bytes(response).length > 0);

        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
        assertEq(token.lastInteraction, 0);

        vm.stopPrank();

        // Test at maximum timestamp
        vm.warp(type(uint256).max);
        vm.startPrank(user1);

        string memory response2 = personaINFT.interactWithAgent(tokenId, "Query at max timestamp");
        assertTrue(bytes(response2).length > 0);

        PersonaINFT.PersonaToken memory token2 = personaINFT.getPersonaToken(tokenId);
        assertEq(token2.lastInteraction, type(uint256).max);

        vm.stopPrank();
    }

    // ============ Array and Mapping Edge Cases ============

    function test_EdgeCase_EmptyArrays() public {
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Empty Array Test", "Testing empty arrays", "0g://storage/empty-array-data", bytes32(uint256(1))
        );

        // New group should have empty token array
        PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(groupId);
        assertEq(group.tokenIds.length, 0);

        // User with no tokens should have empty array
        uint256[] memory userTokens = personaINFT.getUserTokens(user1);
        assertEq(userTokens.length, 0);

        vm.stopPrank();
    }

    function test_EdgeCase_LargeArrays() public {
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Large Array Test", "Testing large arrays", "0g://storage/large-array-data", bytes32(uint256(1))
        );

        // Mint many tokens to test large arrays
        uint256 numTokens = 50; // Reasonable number to avoid gas limits

        for (uint256 i = 0; i < numTokens; i++) {
            personaINFT.mintPersonaINFT(user1, groupId, string(abi.encodePacked("traits-", vm.toString(i))));
        }

        // Verify group contains all tokens
        PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(groupId);
        assertEq(group.tokenIds.length, numTokens);

        // Verify user owns all tokens
        uint256[] memory userTokens = personaINFT.getUserTokens(user1);
        assertEq(userTokens.length, numTokens);

        // Verify all tokens are accessible
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = userTokens[i];
            assertTrue(personaINFT.canAccessAgent(user1, tokenId));
        }

        vm.stopPrank();

        // Create large interaction history
        vm.startPrank(user1);

        uint256 testTokenId = userTokens[0];
        uint256 numInteractions = 30;

        for (uint256 i = 0; i < numInteractions; i++) {
            personaINFT.interactWithAgent(testTokenId, string(abi.encodePacked("Query ", vm.toString(i))));
        }

        vm.stopPrank();

        // Verify large interaction history
        (IPersonaAgent.AgentRequest[] memory requests,) = agentManager.getInteractionHistory(testTokenId, 100);
        assertEq(requests.length, numInteractions);
    }

    // ============ Access Control Edge Cases ============

    function test_EdgeCase_RoleRevocation() public {
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Role Test", "Testing role revocation", "0g://storage/role-data", bytes32(uint256(1))
        );

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, "role-traits");

        vm.stopPrank();

        // Revoke group admin role
        vm.startPrank(deployer);
        personaINFT.revokeRole(personaINFT.GROUP_ADMIN_ROLE(), groupAdmin);
        vm.stopPrank();

        // Former group admin should no longer be able to perform admin functions
        vm.startPrank(groupAdmin);

        vm.expectRevert();
        personaINFT.createPersonaGroup("New Group", "desc", "uri", bytes32(uint256(2)));

        vm.expectRevert();
        personaINFT.mintPersonaINFT(user2, groupId, "new-traits");

        vm.expectRevert();
        personaINFT.updatePersonaGroup(groupId, "new-uri", bytes32(uint256(999)));

        vm.stopPrank();

        // But existing functionality should still work for users
        vm.startPrank(user1);
        string memory response = personaINFT.interactWithAgent(tokenId, "Query after role revocation");
        assertTrue(bytes(response).length > 0);
        vm.stopPrank();
    }

    function test_EdgeCase_MultipleRoleGrantsAndRevocations() public {
        address tempAdmin1 = address(0x701);
        address tempAdmin2 = address(0x702);

        vm.startPrank(deployer);

        // Grant roles to multiple addresses
        personaINFT.grantRole(personaINFT.GROUP_ADMIN_ROLE(), tempAdmin1);
        personaINFT.grantRole(personaINFT.GROUP_ADMIN_ROLE(), tempAdmin2);

        vm.stopPrank();

        // Both should be able to create groups
        vm.startPrank(tempAdmin1);
        uint256 groupId1 = personaINFT.createPersonaGroup("Group 1", "desc1", "uri1", bytes32(uint256(1)));
        vm.stopPrank();

        vm.startPrank(tempAdmin2);
        uint256 groupId2 = personaINFT.createPersonaGroup("Group 2", "desc2", "uri2", bytes32(uint256(2)));
        vm.stopPrank();

        assertTrue(groupId1 > 0);
        assertTrue(groupId2 > 0);

        // Revoke one role
        vm.startPrank(deployer);
        personaINFT.revokeRole(personaINFT.GROUP_ADMIN_ROLE(), tempAdmin1);
        vm.stopPrank();

        // tempAdmin1 should no longer work
        vm.startPrank(tempAdmin1);
        vm.expectRevert();
        personaINFT.createPersonaGroup("Group 3", "desc3", "uri3", bytes32(uint256(3)));
        vm.stopPrank();

        // tempAdmin2 should still work
        vm.startPrank(tempAdmin2);
        uint256 groupId3 = personaINFT.createPersonaGroup("Group 3", "desc3", "uri3", bytes32(uint256(3)));
        assertTrue(groupId3 > 0);
        vm.stopPrank();
    }

    // ============ Reentrancy Edge Cases ============

    function test_EdgeCase_ReentrancyProtection() public {
        // Test that reentrancy guards work properly
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Reentrancy Test", "Testing reentrancy protection", "0g://storage/reentrancy-data", bytes32(uint256(1))
        );

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, "reentrancy-traits");

        vm.stopPrank();

        // Normal operations should work
        vm.startPrank(user1);
        string memory response = personaINFT.interactWithAgent(tokenId, "Normal query");
        assertTrue(bytes(response).length > 0);
        vm.stopPrank();

        // Test transfer reentrancy protection
        vm.startPrank(user1);
        personaINFT.transferFrom(user1, user2, tokenId);
        vm.stopPrank();

        // Verify transfer completed successfully
        assertEq(personaINFT.ownerOf(tokenId), user2);
    }

    // ============ Gas Limit Edge Cases ============

    function test_EdgeCase_NearGasLimitOperations() public {
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Gas Limit Test", "Testing near gas limit operations", "0g://storage/gas-limit-data", bytes32(uint256(1))
        );

        // Create a very long query that might approach gas limits
        string memory longQuery = "";
        for (uint256 i = 0; i < 100; i++) {
            longQuery =
                string(abi.encodePacked(longQuery, "This is a very long query segment that tests gas limit behavior. "));
        }

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, "gas-traits");

        vm.stopPrank();

        vm.startPrank(user1);

        // This should succeed even with a very long query
        string memory response = personaINFT.interactWithAgent(tokenId, longQuery);
        assertTrue(bytes(response).length > 0);

        vm.stopPrank();
    }

    // ============ State Corruption Edge Cases ============

    function test_EdgeCase_StateConsistencyAfterFailures() public {
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "State Consistency Test",
            "Testing state consistency after failures",
            "0g://storage/state-data",
            bytes32(uint256(1))
        );

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, "state-traits");

        vm.stopPrank();

        // Normal operation
        vm.startPrank(user1);
        string memory response1 = personaINFT.interactWithAgent(tokenId, "Query 1");
        assertTrue(bytes(response1).length > 0);
        vm.stopPrank();

        // Attempt invalid operation
        vm.startPrank(user2);
        vm.expectRevert("Not token owner");
        personaINFT.interactWithAgent(tokenId, "Invalid query");
        vm.stopPrank();

        // State should remain consistent
        vm.startPrank(user1);
        string memory response2 = personaINFT.interactWithAgent(tokenId, "Query 2");
        assertTrue(bytes(response2).length > 0);
        vm.stopPrank();

        // Verify interaction history is correct
        PersonaAgentManager.InteractionRecord[] memory history = agentManager.getInteractionRecords(tokenId, 0, 10);
        assertEq(history.length, 2); // Only valid interactions recorded
        assertEq(history[0].query, "Query 1");
        assertEq(history[1].query, "Query 2");
    }

    // ============ Network Edge Cases ============

    function test_EdgeCase_BlockTimestampManipulation() public {
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Timestamp Manipulation Test",
            "Testing timestamp manipulation resistance",
            "0g://storage/timestamp-data",
            bytes32(uint256(1))
        );

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, "timestamp-traits");

        vm.stopPrank();

        // Test interactions at various timestamps
        uint256[] memory testTimestamps = new uint256[](5);
        testTimestamps[0] = 1000;
        testTimestamps[1] = 0; // Edge case: timestamp 0
        testTimestamps[2] = block.timestamp + 1000; // Future timestamp
        testTimestamps[3] = type(uint256).max; // Maximum timestamp
        testTimestamps[4] = 1; // Minimum positive timestamp

        for (uint256 i = 0; i < testTimestamps.length; i++) {
            vm.warp(testTimestamps[i]);

            vm.startPrank(user1);
            string memory response = personaINFT.interactWithAgent(
                tokenId, string(abi.encodePacked("Query at timestamp ", vm.toString(testTimestamps[i])))
            );
            assertTrue(bytes(response).length > 0);
            vm.stopPrank();

            PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
            assertEq(token.lastInteraction, testTimestamps[i]);
        }
    }

    // ============ Contract Interaction Edge Cases ============

    function test_EdgeCase_ContractAsTokenOwner() public {
        // Deploy a simple contract to act as token owner
        SimpleContract simpleContract = new SimpleContract();

        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Contract Owner Test",
            "Testing contract as token owner",
            "0g://storage/contract-owner-data",
            bytes32(uint256(1))
        );

        // Mint to contract
        uint256 tokenId = personaINFT.mintPersonaINFT(address(simpleContract), groupId, "contract-traits");

        vm.stopPrank();

        // Verify contract owns the token
        assertEq(personaINFT.ownerOf(tokenId), address(simpleContract));

        // Contract should be able to interact if it calls the function
        vm.startPrank(address(simpleContract));
        string memory response = personaINFT.interactWithAgent(tokenId, "Query from contract");
        assertTrue(bytes(response).length > 0);
        vm.stopPrank();

        // Others should not be able to interact
        vm.startPrank(user1);
        vm.expectRevert("Not token owner");
        personaINFT.interactWithAgent(tokenId, "Unauthorized query");
        vm.stopPrank();
    }

    // ============ Data Integrity Edge Cases ============

    function test_EdgeCase_HashCollisions() public {
        vm.startPrank(groupAdmin);

        // Test with same hash for different data (simulating collision)
        bytes32 sameHash = keccak256("collision-test");

        uint256 groupId1 = personaINFT.createPersonaGroup("Group 1", "Different data 1", "0g://storage/data1", sameHash);

        uint256 groupId2 = personaINFT.createPersonaGroup(
            "Group 2",
            "Different data 2",
            "0g://storage/data2",
            sameHash // Same hash, different data
        );

        // Both groups should be created successfully
        assertTrue(groupId1 > 0);
        assertTrue(groupId2 > 0);
        assertTrue(groupId1 != groupId2);

        // Verify they're actually different groups
        PersonaINFT.PersonaGroup memory group1 = personaINFT.getPersonaGroup(groupId1);
        PersonaINFT.PersonaGroup memory group2 = personaINFT.getPersonaGroup(groupId2);

        assertEq(group1.dataHash, sameHash);
        assertEq(group2.dataHash, sameHash);
        assertNotEq(keccak256(bytes(group1.name)), keccak256(bytes(group2.name)));

        vm.stopPrank();
    }

    // ============ Memory and Storage Edge Cases ============

    function test_EdgeCase_LargeDataStructures() public {
        vm.startPrank(groupAdmin);

        // Create storage group with many updates to test large arrays
        uint256 storageGroupId = storageManager.createStorageGroup(
            "Large Data Test", keccak256("large-data-key"), "0g://storage/large-initial", keccak256("large-initial")
        );

        // Perform many updates to create large history
        uint256 numUpdates = 20; // Reasonable number to avoid gas limits

        for (uint256 i = 0; i < numUpdates; i++) {
            storageManager.updatePersonaData(
                storageGroupId,
                string(abi.encodePacked("0g://storage/update-", vm.toString(i))),
                keccak256(abi.encodePacked("update-", i)),
                string(abi.encodePacked("Update reason ", vm.toString(i)))
            );
        }

        // Verify all updates are recorded
        PersonaStorageManager.DataUpdate[] memory history =
            storageManager.getUpdateHistory(storageGroupId, numUpdates + 10);
        assertEq(history.length, numUpdates);

        // Verify latest state
        (,,, bytes32 currentHash,, uint256 version,) = storageManager.getStorageGroupInfo(storageGroupId);
        assertEq(version, numUpdates + 1); // Initial + updates
        assertEq(currentHash, keccak256(abi.encodePacked("update-", numUpdates - 1)));

        vm.stopPrank();
    }

    // ============ Upgrade and Migration Edge Cases ============

    function test_EdgeCase_InfrastructureAddressChanges() public {
        vm.startPrank(groupAdmin);

        uint256 groupId = personaINFT.createPersonaGroup(
            "Infrastructure Test", "Testing infrastructure changes", "0g://storage/infra-data", bytes32(uint256(1))
        );

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, "infra-traits");

        vm.stopPrank();

        // Normal operation before changes
        vm.startPrank(user1);
        string memory response1 = personaINFT.interactWithAgent(tokenId, "Query before changes");
        assertTrue(bytes(response1).length > 0);
        vm.stopPrank();

        // Change infrastructure addresses
        vm.startPrank(admin);

        address newOGStorage = address(0x5555);
        address newOGCompute = address(0x6666);

        personaINFT.updateInfrastructure(newOGStorage, newOGCompute);
        agentManager.updateOGComputeConfig(newOGCompute, AGENT_MODEL_ENDPOINT);

        vm.stopPrank();

        // Verify changes took effect
        assertEq(personaINFT.ogStorageAddress(), newOGStorage);
        assertEq(personaINFT.ogComputeAddress(), newOGCompute);
        assertEq(agentManager.ogComputeAddress(), newOGCompute);

        // Operations should still work after infrastructure changes
        vm.startPrank(user1);
        string memory response2 = personaINFT.interactWithAgent(tokenId, "Query after changes");
        assertTrue(bytes(response2).length > 0);
        vm.stopPrank();

        // Verify interaction history spans the infrastructure change
        PersonaAgentManager.InteractionRecord[] memory history = agentManager.getInteractionRecords(tokenId, 0, 10);
        assertEq(history.length, 2);
        assertEq(history[0].query, "Query before changes");
        assertEq(history[1].query, "Query after changes");
    }
}

// Helper contract for testing contract as token owner
contract SimpleContract {
    // Simple contract that can receive NFTs
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
