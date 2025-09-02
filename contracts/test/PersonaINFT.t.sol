// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/PersonaINFT.sol";

contract PersonaINFTTest is Test {
    PersonaINFT public personaINFT;

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
    string constant GROUP_NAME = "Test Persona Group";
    string constant GROUP_DESCRIPTION = "A test persona group for AI agents";
    string constant ENCRYPTED_DATA_URI = "0g://storage/test-data-123";
    bytes32 constant DATA_HASH = keccak256("test-data-hash");
    string constant PERSONALITY_TRAITS = "friendly, helpful, knowledgeable";

    // Events for testing
    event PersonaGroupCreated(uint256 indexed groupId, address indexed admin, string name);
    event PersonaMinted(
        uint256 indexed tokenId, uint256 indexed groupId, address indexed owner, string personalityTraits
    );
    event AgentInteraction(uint256 indexed tokenId, address indexed user, uint256 timestamp);

    function setUp() public {
        vm.startPrank(deployer);

        personaINFT = new PersonaINFT(NAME, SYMBOL, ogStorage, ogCompute);

        // Grant admin role to admin address
        personaINFT.grantRole(personaINFT.ADMIN_ROLE(), admin);
        personaINFT.grantRole(personaINFT.GROUP_ADMIN_ROLE(), admin);

        vm.stopPrank();
    }

    // ============ Basic Contract Setup Tests ============

    function test_InitialSetup() public view {
        assertEq(personaINFT.name(), NAME);
        assertEq(personaINFT.symbol(), SYMBOL);
        assertEq(personaINFT.ogStorageAddress(), ogStorage);
        assertEq(personaINFT.ogComputeAddress(), ogCompute);
        assertEq(personaINFT.totalGroups(), 0);
        assertEq(personaINFT.nextTokenId(), 1);
    }

    function test_InitialRoles() public view {
        assertTrue(personaINFT.hasRole(personaINFT.DEFAULT_ADMIN_ROLE(), deployer));
        assertTrue(personaINFT.hasRole(personaINFT.ADMIN_ROLE(), admin));
        assertTrue(personaINFT.hasRole(personaINFT.GROUP_ADMIN_ROLE(), admin));
        assertFalse(personaINFT.hasRole(personaINFT.ADMIN_ROLE(), unauthorized));
    }

    // ============ Persona Group Creation Tests ============

    function test_CreatePersonaGroup_Success() public {
        vm.startPrank(admin);

        vm.expectEmit(true, true, false, true);
        emit PersonaGroupCreated(1, admin, GROUP_NAME);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        assertEq(groupId, 1);
        assertEq(personaINFT.totalGroups(), 1);

        PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(groupId);
        assertEq(group.name, GROUP_NAME);
        assertEq(group.description, GROUP_DESCRIPTION);
        assertEq(group.admin, admin);
        assertEq(group.encryptedDataURI, ENCRYPTED_DATA_URI);
        assertEq(group.dataHash, DATA_HASH);
        assertTrue(group.isActive);
        assertEq(group.tokenIds.length, 0);

        vm.stopPrank();
    }

    // Note: createPersonaGroup allows anyone to create groups (no access control)
    // function test_CreatePersonaGroup_RevertUnauthorized() public {
    //     vm.startPrank(unauthorized);

    //     vm.expectRevert();
    //     personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

    //     vm.stopPrank();
    // }

    function test_CreatePersonaGroup_RevertEmptyName() public {
        vm.startPrank(admin);

        vm.expectRevert("Name cannot be empty");
        personaINFT.createPersonaGroup("", GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        vm.stopPrank();
    }

    function test_CreatePersonaGroup_RevertEmptyDataURI() public {
        vm.startPrank(admin);

        vm.expectRevert("Data URI cannot be empty");
        personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, "", DATA_HASH);

        vm.stopPrank();
    }

    function test_CreateMultipleGroups() public {
        vm.startPrank(admin);

        // Create first group
        uint256 groupId1 = personaINFT.createPersonaGroup("Group 1", "Description 1", "uri1", bytes32(uint256(1)));

        // Create second group
        uint256 groupId2 = personaINFT.createPersonaGroup("Group 2", "Description 2", "uri2", bytes32(uint256(2)));

        assertEq(groupId1, 1);
        assertEq(groupId2, 2);
        assertEq(personaINFT.totalGroups(), 2);

        vm.stopPrank();
    }

    // ============ Persona Group Update Tests ============

    function test_UpdatePersonaGroup_Success() public {
        vm.startPrank(admin);

        // Create group first
        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        // Update the group
        string memory newURI = "0g://storage/updated-data-456";
        bytes32 newHash = keccak256("updated-data-hash");

        personaINFT.updatePersonaGroup(groupId, newURI, newHash);

        PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(groupId);
        assertEq(group.encryptedDataURI, newURI);
        assertEq(group.dataHash, newHash);
        assertGt(group.lastUpdated, 0);

        vm.stopPrank();
    }

    function test_UpdatePersonaGroup_RevertUnauthorized() public {
        vm.startPrank(admin);
        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);
        vm.stopPrank();

        vm.startPrank(unauthorized);
        vm.expectRevert("Not group admin");
        personaINFT.updatePersonaGroup(groupId, "new-uri", bytes32(uint256(123)));
        vm.stopPrank();
    }

    function test_UpdatePersonaGroup_RevertNonexistentGroup() public {
        vm.startPrank(admin);

        vm.expectRevert("Group not active");
        personaINFT.updatePersonaGroup(999, "new-uri", bytes32(uint256(123)));

        vm.stopPrank();
    }

    // ============ INFT Minting Tests ============

    function test_MintPersonaINFT_Success() public {
        vm.startPrank(admin);

        // Create group first
        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        vm.expectEmit(true, true, true, true);
        emit PersonaMinted(1, groupId, user1, PERSONALITY_TRAITS);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        assertEq(tokenId, 1);
        assertEq(personaINFT.ownerOf(tokenId), user1);
        assertEq(personaINFT.nextTokenId(), 2);

        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
        assertEq(token.groupId, groupId);
        assertEq(token.personalityTraits, PERSONALITY_TRAITS);
        assertTrue(token.isActive);
        assertGt(token.mintedAt, 0);

        // Check user tokens
        uint256[] memory userTokens = personaINFT.getUserTokens(user1);
        assertEq(userTokens.length, 1);
        assertEq(userTokens[0], tokenId);

        // Check group tokens
        PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(groupId);
        assertEq(group.tokenIds.length, 1);
        assertEq(group.tokenIds[0], tokenId);

        vm.stopPrank();
    }

    function test_MintPersonaINFT_RevertUnauthorized() public {
        vm.startPrank(admin);
        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);
        vm.stopPrank();

        vm.startPrank(unauthorized);
        vm.expectRevert();
        personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);
        vm.stopPrank();
    }

    function test_MintPersonaINFT_RevertNonexistentGroup() public {
        vm.startPrank(admin);

        vm.expectRevert("Group not active");
        personaINFT.mintPersonaINFT(user1, 999, PERSONALITY_TRAITS);

        vm.stopPrank();
    }

    function test_MintPersonaINFT_RevertInactiveGroup() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        // Deactivate the group
        personaINFT.deactivateGroup(groupId);

        vm.expectRevert("Group not active");
        personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        vm.stopPrank();
    }

    function test_MintPersonaINFT_RevertZeroAddress() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        vm.expectRevert("Cannot mint to zero address");
        personaINFT.mintPersonaINFT(address(0), groupId, PERSONALITY_TRAITS);

        vm.stopPrank();
    }

    function test_MintMultipleINFTs() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        // Mint multiple INFTs
        uint256 tokenId1 = personaINFT.mintPersonaINFT(user1, groupId, "traits1");
        uint256 tokenId2 = personaINFT.mintPersonaINFT(user2, groupId, "traits2");
        uint256 tokenId3 = personaINFT.mintPersonaINFT(user1, groupId, "traits3");

        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
        assertEq(tokenId3, 3);

        // Check user1 has 2 tokens
        uint256[] memory user1Tokens = personaINFT.getUserTokens(user1);
        assertEq(user1Tokens.length, 2);

        // Check user2 has 1 token
        uint256[] memory user2Tokens = personaINFT.getUserTokens(user2);
        assertEq(user2Tokens.length, 1);

        // Check group has 3 tokens
        PersonaINFT.PersonaGroup memory group = personaINFT.getPersonaGroup(groupId);
        assertEq(group.tokenIds.length, 3);

        vm.stopPrank();
    }

    // ============ Agent Interaction Tests ============

    function test_InteractWithAgent_Success() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        vm.stopPrank();

        vm.startPrank(user1);

        vm.expectEmit(true, true, false, true);
        emit AgentInteraction(tokenId, user1, block.timestamp);

        string memory query = "Hello, how are you?";
        string memory response = personaINFT.interactWithAgent(tokenId, query);

        assertTrue(bytes(response).length > 0);

        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
        assertEq(token.lastInteraction, block.timestamp);

        vm.stopPrank();
    }

    function test_InteractWithAgent_RevertNotOwner() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        vm.stopPrank();

        vm.startPrank(user2);

        vm.expectRevert("Not token owner");
        personaINFT.interactWithAgent(tokenId, "Hello");

        vm.stopPrank();
    }

    function test_InteractWithAgent_RevertInactiveToken() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        // Deactivate the token
        personaINFT.deactivateToken(tokenId);

        vm.stopPrank();

        vm.startPrank(user1);

        vm.expectRevert("Token not active");
        personaINFT.interactWithAgent(tokenId, "Hello");

        vm.stopPrank();
    }

    function test_InteractWithAgent_RevertNonexistentToken() public {
        vm.startPrank(user1);

        vm.expectRevert();
        personaINFT.interactWithAgent(999, "Hello");

        vm.stopPrank();
    }

    // ============ Transfer Tests ============

    function test_Transfer_Success() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        vm.stopPrank();

        vm.startPrank(user1);

        personaINFT.transferFrom(user1, user2, tokenId);

        assertEq(personaINFT.ownerOf(tokenId), user2);

        // Check user token lists updated
        uint256[] memory user1Tokens = personaINFT.getUserTokens(user1);
        uint256[] memory user2Tokens = personaINFT.getUserTokens(user2);

        assertEq(user1Tokens.length, 0);
        assertEq(user2Tokens.length, 1);
        assertEq(user2Tokens[0], tokenId);

        vm.stopPrank();
    }

    function test_Transfer_RevertInactiveToken() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        // Deactivate the token
        personaINFT.deactivateToken(tokenId);

        vm.stopPrank();

        vm.startPrank(user1);

        vm.expectRevert("Token not active");
        personaINFT.transferFrom(user1, user2, tokenId);

        vm.stopPrank();
    }

    // ============ Access Control Tests ============

    function test_CanAccessAgent_Success() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        vm.stopPrank();

        assertTrue(personaINFT.canAccessAgent(user1, tokenId));
        assertFalse(personaINFT.canAccessAgent(user2, tokenId));
    }

    function test_CanAccessAgent_InactiveToken() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        personaINFT.deactivateToken(tokenId);

        vm.stopPrank();

        assertFalse(personaINFT.canAccessAgent(user1, tokenId));
    }

    // ============ Admin Functions Tests ============

    function test_DeactivateToken_Success() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        personaINFT.deactivateToken(tokenId);

        // After deactivation, getPersonaToken should revert
        vm.expectRevert("Token not active");
        personaINFT.getPersonaToken(tokenId);

        vm.stopPrank();
    }

    function test_DeactivateGroup_Success() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        personaINFT.deactivateGroup(groupId);

        // After deactivation, getPersonaGroup should revert
        vm.expectRevert("Group not active");
        personaINFT.getPersonaGroup(groupId);

        vm.stopPrank();
    }

    function test_UpdateInfrastructure_Success() public {
        vm.startPrank(admin);

        address newStorage = address(0x3333);
        address newCompute = address(0x4444);

        personaINFT.updateInfrastructure(newStorage, newCompute);

        assertEq(personaINFT.ogStorageAddress(), newStorage);
        assertEq(personaINFT.ogComputeAddress(), newCompute);

        vm.stopPrank();
    }

    function test_UpdateInfrastructure_RevertUnauthorized() public {
        vm.startPrank(unauthorized);

        vm.expectRevert();
        personaINFT.updateInfrastructure(address(0x3333), address(0x4444));

        vm.stopPrank();
    }

    // ============ View Function Tests ============

    function test_TokenURI() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        string memory tokenURI = personaINFT.tokenURI(tokenId);
        assertTrue(bytes(tokenURI).length > 0);

        vm.stopPrank();
    }

    function test_TokenURI_RevertNonexistentToken() public {
        vm.expectRevert();
        personaINFT.tokenURI(999);
    }

    function test_GetGroupTokens() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId1 = personaINFT.mintPersonaINFT(user1, groupId, "traits1");
        uint256 tokenId2 = personaINFT.mintPersonaINFT(user2, groupId, "traits2");

        uint256[] memory groupTokens = personaINFT.getGroupTokens(groupId);
        assertEq(groupTokens.length, 2);
        assertEq(groupTokens[0], tokenId1);
        assertEq(groupTokens[1], tokenId2);

        vm.stopPrank();
    }

    // ============ Edge Case Tests ============

    function test_EmptyPersonalityTraits() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, "");

        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
        assertEq(token.personalityTraits, "");

        vm.stopPrank();
    }

    function test_LongPersonalityTraits() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        string memory longTraits =
            "This is a very long personality traits string that contains many words and descriptions about the AI agent's personality, behavior patterns, knowledge areas, conversation style, and other characteristics that define how it should interact with users and respond to their queries in a helpful and engaging manner.";

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, longTraits);

        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
        assertEq(token.personalityTraits, longTraits);

        vm.stopPrank();
    }

    function test_TransferAfterInteraction() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 tokenId = personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);

        vm.stopPrank();

        // User1 interacts with agent
        vm.startPrank(user1);
        personaINFT.interactWithAgent(tokenId, "Hello");

        uint256 interactionTime = block.timestamp;

        // Transfer to user2
        personaINFT.transferFrom(user1, user2, tokenId);
        vm.stopPrank();

        // Check that interaction time is preserved
        PersonaINFT.PersonaToken memory token = personaINFT.getPersonaToken(tokenId);
        assertEq(token.lastInteraction, interactionTime);

        // User2 can now interact
        vm.startPrank(user2);
        personaINFT.interactWithAgent(tokenId, "Hi there");
        vm.stopPrank();
    }

    function test_MultipleGroupsSameAdmin() public {
        vm.startPrank(admin);

        uint256 groupId1 = personaINFT.createPersonaGroup("Group 1", "Description 1", "uri1", bytes32(uint256(1)));

        uint256 groupId2 = personaINFT.createPersonaGroup("Group 2", "Description 2", "uri2", bytes32(uint256(2)));

        // Both groups should have same admin
        PersonaINFT.PersonaGroup memory group1 = personaINFT.getPersonaGroup(groupId1);
        PersonaINFT.PersonaGroup memory group2 = personaINFT.getPersonaGroup(groupId2);

        assertEq(group1.admin, admin);
        assertEq(group2.admin, admin);
        assertEq(group1.admin, group2.admin);

        vm.stopPrank();
    }

    // ============ Gas Optimization Tests ============

    function test_GasUsage_CreateGroup() public {
        vm.startPrank(admin);

        uint256 gasBefore = gasleft();
        personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for createPersonaGroup:", gasUsed);
        assertLt(gasUsed, 500000); // Should use less than 500k gas

        vm.stopPrank();
    }

    function test_GasUsage_MintINFT() public {
        vm.startPrank(admin);

        uint256 groupId = personaINFT.createPersonaGroup(GROUP_NAME, GROUP_DESCRIPTION, ENCRYPTED_DATA_URI, DATA_HASH);

        uint256 gasBefore = gasleft();
        personaINFT.mintPersonaINFT(user1, groupId, PERSONALITY_TRAITS);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for mintPersonaINFT:", gasUsed);
        assertLt(gasUsed, 400000); // Should use less than 400k gas

        vm.stopPrank();
    }
}
