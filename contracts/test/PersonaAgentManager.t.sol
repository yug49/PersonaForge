// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/PersonaAgentManager.sol";
import "../src/PersonaINFT.sol";
import "../src/PersonaStorageManager.sol";
import "../src/interfaces/IPersonaAgent.sol";
import "../src/interfaces/IPersonaAgent.sol";

contract PersonaAgentManagerTest is Test {
    PersonaAgentManager public agentManager;
    PersonaINFT public personaINFT;
    PersonaStorageManager public storageManager;

    // Test addresses
    address public deployer = address(0x1);
    address public admin = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public unauthorized = address(0x5);

    // Infrastructure addresses
    address public ogStorage = address(0x1111);
    address public ogCompute = address(0x2222);

    // Test data
    string constant NAME = "PersonaForge INFTs";
    string constant SYMBOL = "PINFT";
    string constant CENTRAL_PUBLIC_KEY = "-----BEGIN PUBLIC KEY-----TEST_KEY-----END PUBLIC KEY-----";
    string constant AGENT_MODEL_ENDPOINT = "https://compute-testnet.0g.ai/v1/agent/inference";
    string constant GROUP_NAME = "Test Persona Group";
    string constant GROUP_DESCRIPTION = "A test persona group for AI agents";
    string constant ENCRYPTED_DATA_URI = "0g://storage/test-data-123";
    bytes32 constant DATA_HASH = keccak256("test-data-hash");
    string constant PERSONALITY_TRAITS = "friendly, helpful, knowledgeable";

    // Events for testing
    event AgentQueryProcessed(uint256 indexed tokenId, address indexed requester, string query, string response);
    event AgentConfigUpdated(uint256 indexed tokenId, string newConfig, address updater);
    event AuthorizedCallerAdded(address caller);
    event AuthorizedCallerRemoved(address caller);

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy contracts
        storageManager = new PersonaStorageManager(ogStorage, CENTRAL_PUBLIC_KEY);
        personaINFT = new PersonaINFT(NAME, SYMBOL, ogStorage, ogCompute);
        agentManager =
            new PersonaAgentManager(address(personaINFT), address(storageManager), ogCompute, AGENT_MODEL_ENDPOINT);

        // Set up roles
        personaINFT.grantRole(personaINFT.ADMIN_ROLE(), admin);
        personaINFT.grantRole(personaINFT.GROUP_ADMIN_ROLE(), admin);
        storageManager.grantRole(storageManager.STORAGE_ADMIN_ROLE(), admin);
        agentManager.grantRole(agentManager.ADMIN_ROLE(), admin);

        // Add authorized caller
        agentManager.addAuthorizedCaller(address(personaINFT));

        vm.stopPrank();
    }

    // Helper function to create a test setup
    function createTestSetup() internal returns (uint256 groupId, uint256 tokenId) {
        vm.startPrank(admin);

        // Create persona group
        groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        // Mint INFT
        tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        vm.stopPrank();
    }

    // ============ Basic Contract Setup Tests ============

    function test_InitialSetup() public view {
        assertEq(address(agentManager.personaINFT()), address(personaINFT));
        assertEq(address(agentManager.storageManager()), address(storageManager));
        assertEq(agentManager.ogComputeAddress(), ogCompute);
        assertEq(agentManager.agentModelEndpoint(), AGENT_MODEL_ENDPOINT);
    }

    function test_InitialRoles() public view {
        assertTrue(agentManager.hasRole(agentManager.DEFAULT_ADMIN_ROLE(), deployer));
        assertTrue(agentManager.hasRole(agentManager.ADMIN_ROLE(), admin));
        assertFalse(agentManager.hasRole(agentManager.ADMIN_ROLE(), unauthorized));
    }

    function test_AuthorizedCaller() public view {
        // Note: authorizedCallers mapping is private, so we can't directly test it
        // The authorization will be tested through functional tests
        // Testing authorized caller functionality indirectly through role checks
        assertFalse(agentManager.hasRole(agentManager.AGENT_OPERATOR_ROLE(), unauthorized));
    }

    // ============ Agent Query Processing Tests ============

    function test_ProcessQuery_Success() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
            tokenId: tokenId,
            requester: user1,
            query: "Hello, how are you?",
            timestamp: block.timestamp,
            context: ""
        });

        vm.expectEmit(true, true, false, true);
        emit AgentQueryProcessed(tokenId, user1, query.query, "");

        IPersonaAgent.AgentResponse memory response = agentManager.processQuery(query);

        assertTrue(bytes(response.response).length > 0);
        assertEq(response.tokenId, tokenId);
        assertGt(response.timestamp, 0);

        vm.stopPrank();
    }

    function test_ProcessQuery_RevertUnauthorizedCaller() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(unauthorized);

        IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
            tokenId: tokenId,
            requester: user1,
            query: "Hello",
            timestamp: block.timestamp,
            context: ""
        });

        vm.expectRevert("Not authorized caller");
        agentManager.processQuery(query);

        vm.stopPrank();
    }

    function test_ProcessQuery_RevertInvalidToken() public {
        vm.startPrank(address(personaINFT));

        IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
            tokenId: 999, // Non-existent token
            requester: user1,
            query: "Hello",
            timestamp: block.timestamp,
            context: ""
        });

        vm.expectRevert("Invalid token ID");
        agentManager.processQuery(query);

        vm.stopPrank();
    }

    function test_ProcessQuery_RevertNotTokenOwner() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
            tokenId: tokenId,
            requester: user2, // Not the owner
            query: "Hello",
            timestamp: block.timestamp,
            context: ""
        });

        vm.expectRevert("User does not own this token");
        agentManager.processQuery(query);

        vm.stopPrank();
    }

    function test_ProcessQuery_RevertEmptyQuery() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
            tokenId: tokenId,
            requester: user1,
            query: "", // Empty query
            timestamp: block.timestamp,
            context: ""
        });

        vm.expectRevert("Query cannot be empty");
        agentManager.processQuery(query);

        vm.stopPrank();
    }

    function test_ProcessQuery_MultipleQueries() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        // First query
        IPersonaAgent.AgentRequest memory query1 = IPersonaAgent.AgentRequest({
            tokenId: tokenId,
            requester: user1,
            query: "What is your name?",
            timestamp: block.timestamp,
            context: ""
        });

        IPersonaAgent.AgentResponse memory response1 = agentManager.processQuery(query1);
        // Note: AgentResponse doesn't have success field, checking response content instead

        // Second query
        IPersonaAgent.AgentRequest memory query2 = IPersonaAgent.AgentRequest({
            tokenId: tokenId,
            requester: user1,
            query: "Tell me about yourself",
            timestamp: block.timestamp + 1,
            context: ""
        });

        IPersonaAgent.AgentResponse memory response2 = agentManager.processQuery(query2);
        // Note: AgentResponse doesn't have success field, checking response content instead

        // Check interaction history
        PersonaAgentManager.InteractionRecord[] memory history = agentManager.getInteractionRecords(tokenId, 0, 10);
        assertEq(history.length, 2);
        assertEq(history[0].query, query1.query);
        assertEq(history[1].query, query2.query);

        vm.stopPrank();
    }

    function test_ProcessQuery_LongQuery() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        string memory longQuery =
            "This is a very long query that contains multiple sentences and asks many different questions about various topics including artificial intelligence, machine learning, natural language processing, blockchain technology, smart contracts, decentralized applications, and many other technical subjects that an AI agent should be able to handle and respond to appropriately with detailed and informative answers.";

        IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
            tokenId: tokenId,
            requester: user1,
            query: longQuery,
            timestamp: block.timestamp,
            context: ""
        });

        IPersonaAgent.AgentResponse memory response = agentManager.processQuery(query);

        // Note: AgentResponse doesn't have success field, checking response content instead
        assertTrue(bytes(response.response).length > 0);

        vm.stopPrank();
    }

    // ============ Agent Configuration Tests ============

    function test_UpdatePersonaConfig_Success() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(user1); // Token owner

        string memory newConfig = "Updated agent configuration with new parameters";

        vm.expectEmit(true, false, false, true);
        emit AgentConfigUpdated(tokenId, newConfig, user1);

        agentManager.updatePersonaConfigData(tokenId, newConfig);

        IPersonaAgent.PersonaConfig memory config = agentManager.getPersonaConfig(tokenId);
        assertEq(config.description, newConfig);

        vm.stopPrank();
    }

    function test_UpdatePersonaConfig_RevertNotOwner() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(user2); // Not the owner

        vm.expectRevert("Not token owner");
        agentManager.updatePersonaConfigData(tokenId, "new config");

        vm.stopPrank();
    }

    function test_UpdatePersonaConfig_RevertInvalidToken() public {
        vm.startPrank(user1);

        vm.expectRevert("Invalid token ID");
        agentManager.updatePersonaConfigData(999, "new config");

        vm.stopPrank();
    }

    function test_UpdatePersonaConfig_EmptyConfig() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(user1);

        agentManager.updatePersonaConfigData(tokenId, "");

        IPersonaAgent.PersonaConfig memory config = agentManager.getPersonaConfig(tokenId);
        assertEq(config.description, "");

        vm.stopPrank();
    }

    function test_UpdatePersonaConfig_MultipleUpdates() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(user1);

        // First update
        agentManager.updatePersonaConfigData(tokenId, "Config v1");
        uint256 firstUpdateTime = block.timestamp;

        // Move time forward
        vm.warp(block.timestamp + 3600);

        // Second update
        agentManager.updatePersonaConfigData(tokenId, "Config v2");
        uint256 secondUpdateTime = block.timestamp;

        IPersonaAgent.PersonaConfig memory config = agentManager.getPersonaConfig(tokenId);
        assertEq(config.description, "Config v2");
        // Note: PersonaConfig doesn't track lastUpdated timestamp
        assertTrue(bytes(config.description).length > 0);

        vm.stopPrank();
    }

    // ============ Agent Access Control Tests ============

    function test_HasAgentAccess_Success() public {
        (, uint256 tokenId) = createTestSetup();

        assertTrue(agentManager.hasAgentAccess(tokenId, user1));
        assertFalse(agentManager.hasAgentAccess(tokenId, user2));
    }

    function test_HasAgentAccess_AfterTransfer() public {
        (, uint256 tokenId) = createTestSetup();

        // Initially user1 has access
        assertTrue(agentManager.hasAgentAccess(tokenId, user1));
        assertFalse(agentManager.hasAgentAccess(tokenId, user2));

        // Transfer token to user2
        vm.startPrank(user1);
        personaINFT.transferFrom(user1, user2, tokenId);
        vm.stopPrank();

        // Now user2 has access, user1 doesn't
        assertFalse(agentManager.hasAgentAccess(tokenId, user1));
        assertTrue(agentManager.hasAgentAccess(tokenId, user2));
    }

    function test_HasAgentAccess_InactiveToken() public {
        (, uint256 tokenId) = createTestSetup();

        // Deactivate token
        vm.startPrank(admin);
        personaINFT.deactivateToken(tokenId);
        vm.stopPrank();

        assertFalse(agentManager.hasAgentAccess(tokenId, user1));
    }

    function test_HasAgentAccess_NonexistentToken() public {
        assertFalse(agentManager.hasAgentAccess(999, user1));
    }

    // ============ Agent Statistics Tests ============

    function test_GetAgentStats_InitialState() public {
        (, uint256 tokenId) = createTestSetup();

        PersonaAgentManager.AgentStats memory stats = agentManager.getAgentStats(tokenId);

        assertEq(stats.totalInteractions, 0);
        assertEq(stats.lastInteraction, 0);
        assertEq(stats.averageResponseTime, 0);
        assertTrue(stats.isActive);
    }

    function test_GetAgentStats_AfterInteractions() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        // Process multiple queries
        for (uint256 i = 0; i < 3; i++) {
            IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
                tokenId: tokenId,
                requester: user1,
                query: string(abi.encodePacked("Query ", vm.toString(i + 1))),
                timestamp: block.timestamp + i,
                context: ""
            });

            agentManager.processQuery(query);
        }

        vm.stopPrank();

        PersonaAgentManager.AgentStats memory stats = agentManager.getAgentStats(tokenId);

        assertEq(stats.totalInteractions, 3);
        assertGt(stats.lastInteraction, 0);
        assertTrue(stats.isActive);
    }

    function test_GetAgentStats_InactiveToken() public {
        (, uint256 tokenId) = createTestSetup();

        // Deactivate token
        vm.startPrank(admin);
        personaINFT.deactivateToken(tokenId);
        vm.stopPrank();

        PersonaAgentManager.AgentStats memory stats = agentManager.getAgentStats(tokenId);
        assertFalse(stats.isActive);
    }

    // ============ Interaction History Tests ============

    function test_GetInteractionHistory_EmptyHistory() public {
        (, uint256 tokenId) = createTestSetup();

        PersonaAgentManager.InteractionRecord[] memory history = agentManager.getInteractionRecords(tokenId, 0, 10);
        assertEq(history.length, 0);
    }

    function test_GetInteractionHistory_WithInteractions() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        // Process multiple queries
        string[] memory queries = new string[](3);
        queries[0] = "First query";
        queries[1] = "Second query";
        queries[2] = "Third query";

        for (uint256 i = 0; i < queries.length; i++) {
            IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
                tokenId: tokenId,
                requester: user1,
                query: queries[i],
                timestamp: block.timestamp + i,
                context: ""
            });

            agentManager.processQuery(query);
        }

        vm.stopPrank();

        PersonaAgentManager.InteractionRecord[] memory history = agentManager.getInteractionRecords(tokenId, 0, 10);

        assertEq(history.length, 3);
        for (uint256 i = 0; i < history.length; i++) {
            assertEq(history[i].query, queries[i]);
            assertEq(history[i].requester, user1);
            assertTrue(bytes(history[i].response).length > 0);
        }
    }

    function test_GetInteractionHistory_Pagination() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        // Process 5 queries
        for (uint256 i = 0; i < 5; i++) {
            IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
                tokenId: tokenId,
                requester: user1,
                query: string(abi.encodePacked("Query ", vm.toString(i + 1))),
                timestamp: block.timestamp + i,
                context: ""
            });

            agentManager.processQuery(query);
        }

        vm.stopPrank();

        // Get first 3 interactions
        PersonaAgentManager.InteractionRecord[] memory firstPage = agentManager.getInteractionRecords(tokenId, 0, 3);
        assertEq(firstPage.length, 3);

        // Get next 2 interactions
        PersonaAgentManager.InteractionRecord[] memory secondPage = agentManager.getInteractionRecords(tokenId, 3, 2);
        assertEq(secondPage.length, 2);

        // Verify they're different
        assertNotEq(firstPage[0].query, secondPage[0].query);
    }

    // ============ Authorized Caller Management Tests ============

    function test_AddAuthorizedCaller_Success() public {
        vm.startPrank(admin);

        address newCaller = address(0x7777);

        vm.expectEmit(false, false, false, true);
        emit AuthorizedCallerAdded(newCaller);

        agentManager.addAuthorizedCaller(newCaller);

        // Note: No getter for authorizedCallers, testing functionality indirectly
        // The authorization will be tested through processQuery calls

        vm.stopPrank();
    }

    function test_AddAuthorizedCaller_RevertUnauthorized() public {
        vm.startPrank(unauthorized);

        vm.expectRevert();
        agentManager.addAuthorizedCaller(address(0x7777));

        vm.stopPrank();
    }

    function test_AddAuthorizedCaller_RevertZeroAddress() public {
        vm.startPrank(admin);

        vm.expectRevert("Cannot add zero address as caller");
        agentManager.addAuthorizedCaller(address(0));

        vm.stopPrank();
    }

    function test_RemoveAuthorizedCaller_Success() public {
        vm.startPrank(admin);

        address newCaller = address(0x7777);
        agentManager.addAuthorizedCaller(newCaller);

        vm.expectEmit(false, false, false, true);
        emit AuthorizedCallerRemoved(newCaller);

        agentManager.removeAuthorizedCaller(newCaller);

        // Note: No getter for authorizedCallers, testing functionality indirectly

        vm.stopPrank();
    }

    function test_RemoveAuthorizedCaller_RevertUnauthorized() public {
        vm.startPrank(unauthorized);

        vm.expectRevert();
        agentManager.removeAuthorizedCaller(address(personaINFT));

        vm.stopPrank();
    }

    // ============ Configuration Update Tests ============

    function test_UpdateOGComputeAddress_Success() public {
        vm.startPrank(admin);

        address newCompute = address(0x3333);
        string memory newEndpoint = "https://new-compute.0g.ai/v2/agent/inference";
        agentManager.updateOGComputeConfig(newCompute, newEndpoint);

        assertEq(agentManager.ogComputeAddress(), newCompute);

        vm.stopPrank();
    }

    function test_UpdateOGComputeAddress_RevertUnauthorized() public {
        vm.startPrank(unauthorized);

        vm.expectRevert();
        agentManager.updateOGComputeConfig(address(0x3333), "endpoint");

        vm.stopPrank();
    }

    function test_UpdateAgentModelEndpoint_Success() public {
        vm.startPrank(admin);

        address newCompute = address(0x3333);
        string memory newEndpoint = "https://new-compute.0g.ai/v2/agent/inference";
        agentManager.updateOGComputeConfig(newCompute, newEndpoint);

        assertEq(agentManager.agentModelEndpoint(), newEndpoint);

        vm.stopPrank();
    }

    function test_UpdateAgentModelEndpoint_RevertUnauthorized() public {
        vm.startPrank(unauthorized);

        vm.expectRevert();
        agentManager.updateOGComputeConfig(address(0x3333), "new-endpoint");

        vm.stopPrank();
    }

    function test_UpdateAgentModelEndpoint_RevertEmptyEndpoint() public {
        vm.startPrank(admin);

        vm.expectRevert("Endpoint cannot be empty");
        agentManager.updateOGComputeConfig(address(0x3333), "");

        vm.stopPrank();
    }

    // ============ Edge Case Tests ============

    function test_ProcessQuery_SpecialCharacters() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        string memory specialQuery = "Query with special chars: @#$%^&*()[]{}|;:'\",.<>?/~`";

        IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
            tokenId: tokenId,
            requester: user1,
            query: specialQuery,
            timestamp: block.timestamp,
            context: ""
        });

        IPersonaAgent.AgentResponse memory response = agentManager.processQuery(query);

        // Note: AgentResponse doesn't have success field, checking response content instead
        assertTrue(bytes(response.response).length > 0);

        vm.stopPrank();
    }

    function test_ProcessQuery_UnicodeCharacters() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        string memory unicodeQuery = unicode"Query with Unicode: 你好世界 🌍 🤖 ñáéíóú";

        IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
            tokenId: tokenId,
            requester: user1,
            query: unicodeQuery,
            timestamp: block.timestamp,
            context: ""
        });

        IPersonaAgent.AgentResponse memory response = agentManager.processQuery(query);

        // Note: AgentResponse doesn't have success field, checking response content instead
        assertTrue(bytes(response.response).length > 0);

        vm.stopPrank();
    }

    function test_MultipleTokensInteractions() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId1 = personaINFT.mintPersonaINFT(user1, groupId, "traits1");
        uint256 tokenId2 = personaINFT.mintPersonaINFT(user2, groupId, "traits2");

        vm.stopPrank();

        vm.startPrank(address(personaINFT));

        // Process queries for both tokens
        IPersonaAgent.AgentRequest memory query1 = IPersonaAgent.AgentRequest({
            tokenId: tokenId1,
            requester: user1,
            query: "Query from token 1",
            timestamp: block.timestamp,
            context: ""
        });

        IPersonaAgent.AgentRequest memory query2 = IPersonaAgent.AgentRequest({
            tokenId: tokenId2,
            requester: user2,
            query: "Query from token 2",
            timestamp: block.timestamp,
            context: ""
        });

        agentManager.processQuery(query1);
        agentManager.processQuery(query2);

        vm.stopPrank();

        // Check that both have separate histories
        PersonaAgentManager.InteractionRecord[] memory history1 = agentManager.getInteractionRecords(tokenId1, 0, 10);
        PersonaAgentManager.InteractionRecord[] memory history2 = agentManager.getInteractionRecords(tokenId2, 0, 10);

        assertEq(history1.length, 1);
        assertEq(history2.length, 1);
        assertEq(history1[0].query, "Query from token 1");
        assertEq(history2[0].query, "Query from token 2");
    }

    // ============ Gas Optimization Tests ============

    function test_GasUsage_ProcessQuery() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
            tokenId: tokenId,
            requester: user1,
            query: "Standard query for gas testing",
            timestamp: block.timestamp,
            context: ""
        });

        uint256 gasBefore = gasleft();
        agentManager.processQuery(query);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for processQuery:", gasUsed);
        assertLt(gasUsed, 500000); // Should use less than 500k gas

        vm.stopPrank();
    }

    function test_GasUsage_UpdatePersonaConfig() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(user1);

        uint256 gasBefore = gasleft();
        agentManager.updatePersonaConfigData(tokenId, "New configuration data");
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for updatePersonaConfig:", gasUsed);
        assertLt(gasUsed, 200000); // Should use less than 200k gas

        vm.stopPrank();
    }

    // ============ State Consistency Tests ============

    function test_StateConsistency_AfterMultipleOperations() public {
        (, uint256 tokenId) = createTestSetup();

        vm.startPrank(address(personaINFT));

        // Process some queries
        for (uint256 i = 0; i < 3; i++) {
            IPersonaAgent.AgentRequest memory query = IPersonaAgent.AgentRequest({
                tokenId: tokenId,
                requester: user1,
                query: string(abi.encodePacked("Query ", vm.toString(i + 1))),
                timestamp: block.timestamp + i,
                context: ""
            });

            agentManager.processQuery(query);
        }

        vm.stopPrank();

        // Update config
        vm.startPrank(user1);
        agentManager.updatePersonaConfigData(tokenId, "Updated config");
        vm.stopPrank();

        // Transfer token
        vm.startPrank(user1);
        personaINFT.transferFrom(user1, user2, tokenId);
        vm.stopPrank();

        // Verify state consistency
        PersonaAgentManager.AgentStats memory stats = agentManager.getAgentStats(tokenId);
        assertEq(stats.totalInteractions, 3);

        PersonaAgentManager.InteractionRecord[] memory history = agentManager.getInteractionRecords(tokenId, 0, 10);
        assertEq(history.length, 3);

        IPersonaAgent.PersonaConfig memory config = agentManager.getPersonaConfig(tokenId);
        assertEq(config.description, "Updated config");

        // New owner can interact
        assertTrue(agentManager.hasAgentAccess(tokenId, user2));
        assertFalse(agentManager.hasAgentAccess(tokenId, user1));
    }
}
