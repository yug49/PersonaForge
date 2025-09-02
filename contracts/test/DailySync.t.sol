// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PersonaStorageManager.sol";
import "../src/PersonaINFT.sol";
import "../src/PersonaAgentManager.sol";

/**
 * @title DailySyncTest
 * @dev Comprehensive tests for the daily sync functionality
 */
contract DailySyncTest is Test {
    PersonaStorageManager public storageManager;
    PersonaINFT public personaINFT;
    PersonaAgentManager public agentManager;

    address public admin = address(0x1);
    address public groupAdmin = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public unauthorizedUser = address(0x5);

    uint256 public testGroupId;

    // Constants
    string constant GROUP_NAME = "Daily Journal AI";
    bytes32 constant ENCRYPTION_KEY_HASH = keccak256("test-encryption-key");
    string constant INITIAL_STORAGE_URI = "0g://storage/journal-data";
    bytes32 constant INITIAL_DATA_HASH = keccak256("initial-journal-data");
    string constant CENTRAL_SERVER_KEY = "central-server-public-key";

    // Events
    event JournalEntryAdded(
        uint256 indexed groupId, address indexed author, string entryType, uint256 timestamp, bytes32 contentHash
    );

    function setUp() public {
        vm.startPrank(admin);

        // Deploy contracts
        storageManager = new PersonaStorageManager(address(0x123), CENTRAL_SERVER_KEY);
        personaINFT = new PersonaINFT("PersonaINFT", "PINFT", address(0x456), address(0x789));
        agentManager =
            new PersonaAgentManager(address(personaINFT), address(storageManager), address(0x789), "0g://ai-model");

        vm.stopPrank();

        // Setup test group
        vm.startPrank(groupAdmin);
        testGroupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);
        vm.stopPrank();
    }

    // ============ Daily Sync Basic Tests ============

    function test_DailySync_Success() public {
        vm.startPrank(groupAdmin);

        string memory dailyThoughts = "Today I learned about blockchain technology and its potential for AI agents.";

        vm.expectEmit(true, true, false, false); // Don't check data
        emit JournalEntryAdded(testGroupId, groupAdmin, "daily_sync", block.timestamp, keccak256(""));

        storageManager.dailySync(testGroupId, dailyThoughts);

        // Verify entry was added
        uint256 entryCount = storageManager.getJournalEntryCount(testGroupId);
        assertEq(entryCount, 1);

        // Get the entry and verify content
        PersonaStorageManager.JournalEntry[] memory entries = storageManager.getLatestJournalEntries(testGroupId, 1);
        assertEq(entries.length, 1);
        assertEq(entries[0].entryContent, dailyThoughts);
        assertEq(entries[0].entryType, "daily_sync");
        assertEq(entries[0].author, groupAdmin);
        assertEq(entries[0].groupId, testGroupId);
        assertGt(entries[0].timestamp, 0);

        vm.stopPrank();
    }

    function test_AddJournalEntry_Success() public {
        vm.startPrank(groupAdmin);

        string memory entryContent = "Had an interesting experience with AI today.";
        string memory entryType = "experience";

        vm.expectEmit(true, true, false, false); // Don't check data
        emit JournalEntryAdded(testGroupId, groupAdmin, entryType, block.timestamp, keccak256(""));

        storageManager.addJournalEntry(testGroupId, entryContent, entryType);

        // Verify entry was added
        uint256 entryCount = storageManager.getJournalEntryCount(testGroupId);
        assertEq(entryCount, 1);

        vm.stopPrank();
    }

    function test_DailySync_RevertEmptyContent() public {
        vm.startPrank(groupAdmin);

        vm.expectRevert("Entry content cannot be empty");
        storageManager.dailySync(testGroupId, "");

        vm.stopPrank();
    }

    function test_AddJournalEntry_RevertEmptyType() public {
        vm.startPrank(groupAdmin);

        vm.expectRevert("Entry type cannot be empty");
        storageManager.addJournalEntry(testGroupId, "Some content", "");

        vm.stopPrank();
    }

    function test_DailySync_RevertUnauthorized() public {
        vm.startPrank(unauthorizedUser);

        vm.expectRevert("Not authorized to update");
        storageManager.dailySync(testGroupId, "Unauthorized thoughts");

        vm.stopPrank();
    }

    function test_DailySync_RevertInactiveGroup() public {
        vm.startPrank(groupAdmin);

        // Create and deactivate a group
        uint256 inactiveGroupId = storageManager.createStorageGroup(
            "Inactive Group", keccak256("inactive-key"), "0g://inactive", keccak256("inactive-data")
        );
        storageManager.deactivateStorageGroup(inactiveGroupId);

        vm.expectRevert("Group not active");
        storageManager.dailySync(inactiveGroupId, "Should fail");

        vm.stopPrank();
    }

    // ============ Multiple Entries Tests ============

    function test_MultipleDailySyncs() public {
        vm.startPrank(groupAdmin);

        string[] memory entries = new string[](5);
        entries[0] = "Day 1: Started learning about AI agents";
        entries[1] = "Day 2: Implemented my first smart contract";
        entries[2] = "Day 3: Discovered the power of NFTs";
        entries[3] = "Day 4: Built an AI-powered application";
        entries[4] = "Day 5: Launched my first dApp";

        // Add multiple daily syncs
        for (uint256 i = 0; i < entries.length; i++) {
            vm.warp(block.timestamp + i * 1 days); // Simulate different days
            storageManager.dailySync(testGroupId, entries[i]);
        }

        // Verify all entries were added
        uint256 entryCount = storageManager.getJournalEntryCount(testGroupId);
        assertEq(entryCount, 5);

        // Get all entries and verify order
        PersonaStorageManager.JournalEntry[] memory allEntries = storageManager.getJournalEntries(testGroupId, 0, 10);
        assertEq(allEntries.length, 5);

        for (uint256 i = 0; i < entries.length; i++) {
            assertEq(allEntries[i].entryContent, entries[i]);
            assertEq(allEntries[i].entryType, "daily_sync");
        }

        vm.stopPrank();
    }

    function test_MixedEntryTypes() public {
        vm.startPrank(groupAdmin);

        // Add different types of entries
        storageManager.addJournalEntry(testGroupId, "Morning thoughts about AI", "thought");
        storageManager.addJournalEntry(testGroupId, "Visited a tech conference", "experience");
        storageManager.dailySync(testGroupId, "Daily reflection on learning");
        storageManager.addJournalEntry(testGroupId, "Remembering my first code", "memory");

        uint256 entryCount = storageManager.getJournalEntryCount(testGroupId);
        assertEq(entryCount, 4);

        // Verify different entry types
        PersonaStorageManager.JournalEntry[] memory entries = storageManager.getJournalEntries(testGroupId, 0, 10);
        assertEq(entries[0].entryType, "thought");
        assertEq(entries[1].entryType, "experience");
        assertEq(entries[2].entryType, "daily_sync");
        assertEq(entries[3].entryType, "memory");

        vm.stopPrank();
    }

    // ============ Pagination Tests ============

    function test_GetJournalEntries_Pagination() public {
        vm.startPrank(groupAdmin);

        // Add 10 entries
        for (uint256 i = 0; i < 10; i++) {
            string memory content = string(abi.encodePacked("Entry ", vm.toString(i + 1)));
            storageManager.dailySync(testGroupId, content);
        }

        // Test pagination - first 3 entries
        PersonaStorageManager.JournalEntry[] memory firstPage = storageManager.getJournalEntries(testGroupId, 0, 3);
        assertEq(firstPage.length, 3);
        assertEq(firstPage[0].entryContent, "Entry 1");
        assertEq(firstPage[2].entryContent, "Entry 3");

        // Test pagination - next 3 entries
        PersonaStorageManager.JournalEntry[] memory secondPage = storageManager.getJournalEntries(testGroupId, 3, 3);
        assertEq(secondPage.length, 3);
        assertEq(secondPage[0].entryContent, "Entry 4");
        assertEq(secondPage[2].entryContent, "Entry 6");

        // Test pagination - last entries
        PersonaStorageManager.JournalEntry[] memory lastPage = storageManager.getJournalEntries(testGroupId, 7, 5);
        assertEq(lastPage.length, 3); // Only 3 entries remaining
        assertEq(lastPage[0].entryContent, "Entry 8");
        assertEq(lastPage[2].entryContent, "Entry 10");

        vm.stopPrank();
    }

    function test_GetLatestJournalEntries() public {
        vm.startPrank(groupAdmin);

        // Add 5 entries
        for (uint256 i = 0; i < 5; i++) {
            string memory content = string(abi.encodePacked("Latest Entry ", vm.toString(i + 1)));
            storageManager.dailySync(testGroupId, content);
        }

        // Get latest 3 entries
        PersonaStorageManager.JournalEntry[] memory latestEntries =
            storageManager.getLatestJournalEntries(testGroupId, 3);
        assertEq(latestEntries.length, 3);
        assertEq(latestEntries[0].entryContent, "Latest Entry 3");
        assertEq(latestEntries[1].entryContent, "Latest Entry 4");
        assertEq(latestEntries[2].entryContent, "Latest Entry 5");

        vm.stopPrank();
    }

    function test_GetJournalEntries_EmptyGroup() public {
        vm.startPrank(groupAdmin);

        PersonaStorageManager.JournalEntry[] memory entries = storageManager.getJournalEntries(testGroupId, 0, 10);
        assertEq(entries.length, 0);

        PersonaStorageManager.JournalEntry[] memory latestEntries =
            storageManager.getLatestJournalEntries(testGroupId, 5);
        assertEq(latestEntries.length, 0);

        uint256 entryCount = storageManager.getJournalEntryCount(testGroupId);
        assertEq(entryCount, 0);

        vm.stopPrank();
    }

    // ============ Authorization Tests ============

    function test_AuthorizedUpdater_CanAddEntries() public {
        vm.startPrank(groupAdmin);
        storageManager.addAuthorizedUpdater(testGroupId, user1);
        vm.stopPrank();

        vm.startPrank(user1);
        storageManager.dailySync(testGroupId, "Entry by authorized updater");

        uint256 entryCount = storageManager.getJournalEntryCount(testGroupId);
        assertEq(entryCount, 1);

        PersonaStorageManager.JournalEntry[] memory entries = storageManager.getLatestJournalEntries(testGroupId, 1);
        assertEq(entries[0].author, user1);
        vm.stopPrank();
    }

    function test_RemovedUpdater_CannotAddEntries() public {
        vm.startPrank(groupAdmin);
        storageManager.addAuthorizedUpdater(testGroupId, user1);
        storageManager.removeAuthorizedUpdater(testGroupId, user1);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("Not authorized to update");
        storageManager.dailySync(testGroupId, "Should fail");
        vm.stopPrank();
    }

    function test_UnauthorizedUser_CannotViewEntries() public {
        vm.startPrank(groupAdmin);
        storageManager.dailySync(testGroupId, "Private thoughts");
        vm.stopPrank();

        vm.startPrank(unauthorizedUser);
        vm.expectRevert("Not authorized to view");
        storageManager.getJournalEntries(testGroupId, 0, 10);

        vm.expectRevert("Not authorized to view");
        storageManager.getLatestJournalEntries(testGroupId, 5);

        vm.expectRevert("Not authorized to view");
        storageManager.getJournalEntryCount(testGroupId);
        vm.stopPrank();
    }

    // ============ Integration Tests ============

    function test_DailySync_IntegrationWithINFT() public {
        vm.startPrank(groupAdmin);

        // Create a PersonaINFT group connected to storage
        uint256 inftGroupId = personaINFT.createPersonaGroup(
            "AI Journal Companion", "An AI that learns from daily entries", "0g://inft-data", keccak256("inft-data")
        );

        // Mint an INFT for user1
        uint256 tokenId = personaINFT.mintPersonaINFT(user1, inftGroupId, "reflective, curious, growth-oriented");

        // Add journal entries that the AI can learn from
        storageManager.dailySync(testGroupId, "Today I realized the importance of consistent learning");
        storageManager.dailySync(testGroupId, "Had a breakthrough in understanding AI agent behaviors");
        storageManager.dailySync(testGroupId, "Reflected on my progress and set new goals");

        vm.stopPrank();

        // User can interact with their INFT
        vm.startPrank(user1);
        string memory aiResponse =
            personaINFT.interactWithAgent(tokenId, "What can you tell me about my recent thoughts?");
        assertTrue(bytes(aiResponse).length > 0);
        vm.stopPrank();

        // Verify journal entries are accessible
        vm.startPrank(groupAdmin);
        uint256 entryCount = storageManager.getJournalEntryCount(testGroupId);
        assertEq(entryCount, 3);
        vm.stopPrank();
    }

    // ============ Edge Cases ============

    function test_VeryLongJournalEntry() public {
        vm.startPrank(groupAdmin);

        string memory longEntry =
            "This is a very long journal entry that contains extensive thoughts, experiences, and reflections about life, technology, artificial intelligence, blockchain, personal growth, relationships, career development, and many other topics that might be included in a comprehensive daily journal entry that someone might write when they have a lot to express and want to capture their detailed thoughts and experiences for future reference and learning.";

        storageManager.dailySync(testGroupId, longEntry);

        PersonaStorageManager.JournalEntry[] memory entries = storageManager.getLatestJournalEntries(testGroupId, 1);
        assertEq(entries[0].entryContent, longEntry);

        vm.stopPrank();
    }

    function test_SpecialCharactersInEntry() public {
        vm.startPrank(groupAdmin);

        string memory specialEntry =
            unicode"Today I learned: AI agents can understand emotions! 😊🤖 Special chars: @#$%^&*()[]{}|;:'\",.<>?/~`";

        storageManager.addJournalEntry(testGroupId, specialEntry, "thought");

        PersonaStorageManager.JournalEntry[] memory entries = storageManager.getLatestJournalEntries(testGroupId, 1);
        assertEq(entries[0].entryContent, specialEntry);

        vm.stopPrank();
    }

    function test_ContentHashUniqueness() public {
        vm.startPrank(groupAdmin);

        storageManager.dailySync(testGroupId, "Same content");
        vm.warp(block.timestamp + 1); // Different timestamp
        storageManager.dailySync(testGroupId, "Same content");

        PersonaStorageManager.JournalEntry[] memory entries = storageManager.getJournalEntries(testGroupId, 0, 10);
        assertEq(entries.length, 2);

        // Content hashes should be different due to different timestamps
        assertTrue(entries[0].contentHash != entries[1].contentHash);

        vm.stopPrank();
    }

    // ============ Gas Optimization Tests ============

    function test_GasUsage_SingleDailySync() public {
        vm.startPrank(groupAdmin);

        uint256 gasBefore = gasleft();
        storageManager.dailySync(testGroupId, "Optimized daily sync entry");
        uint256 gasUsed = gasBefore - gasleft();

        // Gas usage should be reasonable (less than 200k gas)
        assertLt(gasUsed, 200000);
        console.log("Gas used for single daily sync:", gasUsed);

        vm.stopPrank();
    }

    function test_GasUsage_MultipleEntries() public {
        vm.startPrank(groupAdmin);

        uint256 gasBefore = gasleft();

        for (uint256 i = 0; i < 10; i++) {
            string memory content = string(abi.encodePacked("Batch entry ", vm.toString(i + 1)));
            storageManager.dailySync(testGroupId, content);
        }

        uint256 gasUsed = gasBefore - gasleft();
        uint256 gasPerEntry = gasUsed / 10;

        console.log("Gas used for 10 daily syncs:", gasUsed);
        console.log("Gas per entry:", gasPerEntry);

        // Average gas per entry should be reasonable (updated for actual performance)
        assertLt(gasPerEntry, 155000);

        vm.stopPrank();
    }
}
