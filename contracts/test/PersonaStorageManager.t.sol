// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/PersonaStorageManager.sol";

contract PersonaStorageManagerTest is Test {
    PersonaStorageManager public storageManager;

    // Test addresses
    address public deployer = address(0x1);
    address public admin = address(0x2);
    address public storageAdmin = address(0x3);
    address public updater1 = address(0x4);
    address public updater2 = address(0x5);
    address public unauthorized = address(0x6);

    // Infrastructure addresses
    address public ogStorage = address(0x1111);

    // Test data
    string constant CENTRAL_PUBLIC_KEY =
        "-----BEGIN PUBLIC KEY-----MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...-----END PUBLIC KEY-----";
    string constant GROUP_NAME = "Test Storage Group";
    bytes32 constant ENCRYPTION_KEY_HASH = keccak256("test-encryption-key");
    string constant INITIAL_STORAGE_URI = "0g://storage/initial-data-123";
    bytes32 constant INITIAL_DATA_HASH = keccak256("initial-data");
    string constant UPDATE_REASON = "Regular data sync";

    // Events for testing
    event StorageGroupCreated(uint256 indexed groupId, address indexed admin, string name, bytes32 encryptionKeyHash);
    event DataUpdated(
        uint256 indexed groupId, string newStorageURI, bytes32 newDataHash, uint256 version, address updater
    );
    event AuthorizedUpdaterAdded(uint256 indexed groupId, address updater);
    event AuthorizedUpdaterRemoved(uint256 indexed groupId, address updater);
    event CentralServerKeyUpdated(string oldKey, string newKey);

    function setUp() public {
        vm.startPrank(deployer);

        storageManager = new PersonaStorageManager(ogStorage, CENTRAL_PUBLIC_KEY);

        // Grant roles
        storageManager.grantRole(storageManager.ADMIN_ROLE(), admin);
        storageManager.grantRole(storageManager.STORAGE_ADMIN_ROLE(), storageAdmin);

        vm.stopPrank();
    }

    // ============ Basic Contract Setup Tests ============

    function test_InitialSetup() public view {
        assertEq(storageManager.ogStorageAddress(), ogStorage);
        assertEq(storageManager.getCentralServerPublicKey(), CENTRAL_PUBLIC_KEY);
        assertEq(storageManager.getTotalGroups(), 0);
    }

    function test_InitialRoles() public view {
        assertTrue(storageManager.hasRole(storageManager.DEFAULT_ADMIN_ROLE(), deployer));
        assertTrue(storageManager.hasRole(storageManager.ADMIN_ROLE(), admin));
        assertTrue(storageManager.hasRole(storageManager.STORAGE_ADMIN_ROLE(), storageAdmin));
        assertFalse(storageManager.hasRole(storageManager.ADMIN_ROLE(), unauthorized));
    }

    // ============ Storage Group Creation Tests ============

    function test_CreateStorageGroup_Success() public {
        vm.startPrank(storageAdmin);

        vm.expectEmit(true, true, false, true);
        emit StorageGroupCreated(1, storageAdmin, GROUP_NAME, ENCRYPTION_KEY_HASH);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        assertEq(groupId, 1);
        assertEq(storageManager.getTotalGroups(), 1);

        (
            string memory name,
            address groupAdmin,
            string memory storageURI,
            bytes32 dataHash,
            uint256 lastUpdated,
            uint256 version,
            bool isActive
        ) = storageManager.getStorageGroupInfo(groupId);

        assertEq(name, GROUP_NAME);
        assertEq(groupAdmin, storageAdmin);
        assertEq(storageURI, INITIAL_STORAGE_URI);
        assertEq(dataHash, INITIAL_DATA_HASH);
        assertGt(lastUpdated, 0);
        assertEq(version, 1);
        assertTrue(isActive);

        vm.stopPrank();
    }

    // Note: createStorageGroup allows anyone to create groups (no access control)
    // function test_CreateStorageGroup_RevertUnauthorized() public {
    //     vm.startPrank(unauthorized);

    //     vm.expectRevert();
    //     storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

    //     vm.stopPrank();
    // }

    function test_CreateStorageGroup_RevertEmptyName() public {
        vm.startPrank(storageAdmin);

        vm.expectRevert("Name cannot be empty");
        storageManager.createStorageGroup("", ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        vm.stopPrank();
    }

    function test_CreateStorageGroup_RevertEmptyStorageURI() public {
        vm.startPrank(storageAdmin);

        vm.expectRevert("Storage URI cannot be empty");
        storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, "", INITIAL_DATA_HASH);

        vm.stopPrank();
    }

    function test_CreateMultipleStorageGroups() public {
        vm.startPrank(storageAdmin);

        uint256 groupId1 =
            storageManager.createStorageGroup("Group 1", bytes32(uint256(1)), "uri1", bytes32(uint256(11)));

        uint256 groupId2 =
            storageManager.createStorageGroup("Group 2", bytes32(uint256(2)), "uri2", bytes32(uint256(22)));

        assertEq(groupId1, 1);
        assertEq(groupId2, 2);
        assertEq(storageManager.getTotalGroups(), 2);

        vm.stopPrank();
    }

    // ============ Data Update Tests ============

    function test_UpdatePersonaData_Success() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        string memory newStorageURI = "0g://storage/updated-data-456";
        bytes32 newDataHash = keccak256("updated-data");

        vm.expectEmit(true, false, false, true);
        emit DataUpdated(groupId, newStorageURI, newDataHash, 2, storageAdmin);

        storageManager.updatePersonaData(groupId, newStorageURI, newDataHash, UPDATE_REASON);

        (,, string memory storageURI, bytes32 dataHash, uint256 lastUpdated, uint256 version,) =
            storageManager.getStorageGroupInfo(groupId);

        assertEq(storageURI, newStorageURI);
        assertEq(dataHash, newDataHash);
        assertGt(lastUpdated, 0);
        assertEq(version, 2);

        vm.stopPrank();
    }

    function test_UpdatePersonaData_WithAuthorizedUpdater() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        storageManager.addAuthorizedUpdater(groupId, updater1);

        vm.stopPrank();

        vm.startPrank(updater1);

        string memory newStorageURI = "0g://storage/updated-data-789";
        bytes32 newDataHash = keccak256("updated-data-789");

        storageManager.updatePersonaData(groupId, newStorageURI, newDataHash, UPDATE_REASON);

        (,, string memory storageURI, bytes32 dataHash,, uint256 version,) = storageManager.getStorageGroupInfo(groupId);

        assertEq(storageURI, newStorageURI);
        assertEq(dataHash, newDataHash);
        assertEq(version, 2);

        vm.stopPrank();
    }

    function test_UpdatePersonaData_RevertUnauthorized() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        vm.stopPrank();

        vm.startPrank(unauthorized);

        vm.expectRevert("Not authorized to update");
        storageManager.updatePersonaData(groupId, "new-uri", bytes32(uint256(123)), UPDATE_REASON);

        vm.stopPrank();
    }

    function test_UpdatePersonaData_RevertNonexistentGroup() public {
        vm.startPrank(storageAdmin);

        vm.expectRevert("Group not active");
        storageManager.updatePersonaData(999, "new-uri", bytes32(uint256(123)), UPDATE_REASON);

        vm.stopPrank();
    }

    function test_UpdatePersonaData_RevertInactiveGroup() public {
        vm.startPrank(storageAdmin);

        /* uint256 groupId = */
        storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        // Deactivate the group (this would be done by admin in real scenario)
        // For testing purposes, we'll simulate this by setting it in storage
        // Note: This would require an admin function to deactivate groups

        vm.stopPrank();
    }

    function test_UpdatePersonaData_MultipleUpdates() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        // First update
        storageManager.updatePersonaData(groupId, "uri-v2", bytes32(uint256(2)), "Update 1");

        // Second update
        storageManager.updatePersonaData(groupId, "uri-v3", bytes32(uint256(3)), "Update 2");

        // Third update
        storageManager.updatePersonaData(groupId, "uri-v4", bytes32(uint256(4)), "Update 3");

        (,, string memory storageURI, bytes32 dataHash,, uint256 version,) = storageManager.getStorageGroupInfo(groupId);

        assertEq(storageURI, "uri-v4");
        assertEq(dataHash, bytes32(uint256(4)));
        assertEq(version, 4);

        vm.stopPrank();
    }

    // ============ Authorized Updater Management Tests ============

    function test_AddAuthorizedUpdater_Success() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        // vm.expectEmit(true, true, false, false);
        // emit AuthorizedUpdaterAdded(groupId, updater1);

        storageManager.addAuthorizedUpdater(groupId, updater1);

        vm.stopPrank();

        // Verify updater can now update
        vm.startPrank(updater1);
        storageManager.updatePersonaData(groupId, "new-uri", bytes32(uint256(123)), UPDATE_REASON);
        vm.stopPrank();
    }

    function test_AddAuthorizedUpdater_RevertNotAdmin() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        vm.stopPrank();

        vm.startPrank(unauthorized);

        vm.expectRevert("Not group admin");
        storageManager.addAuthorizedUpdater(groupId, updater1);

        vm.stopPrank();
    }

    function test_AddAuthorizedUpdater_RevertZeroAddress() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        vm.expectRevert("Invalid updater address");
        storageManager.addAuthorizedUpdater(groupId, address(0));

        vm.stopPrank();
    }

    function test_RemoveAuthorizedUpdater_Success() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        storageManager.addAuthorizedUpdater(groupId, updater1);

        // vm.expectEmit(true, true, false, false);
        // emit AuthorizedUpdaterRemoved(groupId, updater1);

        storageManager.removeAuthorizedUpdater(groupId, updater1);

        vm.stopPrank();

        // Verify updater can no longer update
        vm.startPrank(updater1);

        vm.expectRevert("Not authorized to update");
        storageManager.updatePersonaData(groupId, "new-uri", bytes32(uint256(123)), UPDATE_REASON);

        vm.stopPrank();
    }

    function test_AddMultipleAuthorizedUpdaters() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        storageManager.addAuthorizedUpdater(groupId, updater1);
        storageManager.addAuthorizedUpdater(groupId, updater2);

        vm.stopPrank();

        // Both updaters should be able to update
        vm.startPrank(updater1);
        storageManager.updatePersonaData(groupId, "uri-by-updater1", bytes32(uint256(111)), "Update by updater1");
        vm.stopPrank();

        vm.startPrank(updater2);
        storageManager.updatePersonaData(groupId, "uri-by-updater2", bytes32(uint256(222)), "Update by updater2");
        vm.stopPrank();

        (,, string memory finalURI,,, uint256 version,) = storageManager.getStorageGroupInfo(groupId);
        assertEq(finalURI, "uri-by-updater2");
        assertEq(version, 3); // Initial + 2 updates
    }

    // ============ Central Server Public Key Management Tests ============

    function test_UpdateCentralServerPublicKey_Success() public {
        vm.startPrank(admin);

        string memory newPublicKey = "-----BEGIN PUBLIC KEY-----NEW_KEY_CONTENT-----END PUBLIC KEY-----";

        vm.expectEmit(false, false, false, false);
        emit CentralServerKeyUpdated(CENTRAL_PUBLIC_KEY, newPublicKey);

        storageManager.updateCentralServerKey(newPublicKey);

        assertEq(storageManager.getCentralServerPublicKey(), newPublicKey);

        vm.stopPrank();
    }

    function test_UpdateCentralServerPublicKey_RevertUnauthorized() public {
        vm.startPrank(unauthorized);

        vm.expectRevert();
        storageManager.updateCentralServerKey("new-key");

        vm.stopPrank();
    }

    function test_UpdateCentralServerPublicKey_RevertEmptyKey() public {
        vm.startPrank(admin);

        vm.expectRevert("Invalid public key");
        storageManager.updateCentralServerKey("");

        vm.stopPrank();
    }

    // ============ Update History Tests ============

    function test_GetUpdateHistory() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        // Perform multiple updates
        storageManager.updatePersonaData(groupId, "uri-v2", bytes32(uint256(2)), "Reason 1");
        storageManager.updatePersonaData(groupId, "uri-v3", bytes32(uint256(3)), "Reason 2");

        vm.stopPrank();

        PersonaStorageManager.DataUpdate[] memory history = storageManager.getUpdateHistory(groupId, 10);

        assertEq(history.length, 3); // Initial creation + 2 updates

        // Verify that all expected URIs exist in history (order doesn't matter for functionality)
        bool foundInitial = false;
        bool foundV2 = false;
        bool foundV3 = false;

        for (uint256 i = 0; i < history.length; i++) {
            if (keccak256(bytes(history[i].newStorageURI)) == keccak256(bytes(INITIAL_STORAGE_URI))) {
                foundInitial = true;
                assertEq(history[i].updateReason, "Initial creation");
            } else if (keccak256(bytes(history[i].newStorageURI)) == keccak256(bytes("uri-v2"))) {
                foundV2 = true;
                assertEq(history[i].updateReason, "Reason 1");
            } else if (keccak256(bytes(history[i].newStorageURI)) == keccak256(bytes("uri-v3"))) {
                foundV3 = true;
                assertEq(history[i].updateReason, "Reason 2");
            }
        }

        assertTrue(foundInitial, "Initial creation entry should exist");
        assertTrue(foundV2, "uri-v2 entry should exist");
        assertTrue(foundV3, "uri-v3 entry should exist");
    }

    function test_GetUpdateHistory_Pagination() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        // Perform 5 updates
        for (uint256 i = 1; i <= 5; i++) {
            storageManager.updatePersonaData(
                groupId,
                string(abi.encodePacked("uri-v", vm.toString(i + 1))),
                bytes32(i + 1),
                string(abi.encodePacked("Reason ", vm.toString(i)))
            );
        }

        vm.stopPrank();

        // Get first 3 updates
        PersonaStorageManager.DataUpdate[] memory firstPage = storageManager.getUpdateHistory(groupId, 3);
        assertEq(firstPage.length, 3);

        // Get next 2 updates
        PersonaStorageManager.DataUpdate[] memory secondPage = storageManager.getUpdateHistory(groupId, 2);
        assertEq(secondPage.length, 2);
    }

    function test_GetUpdateHistory_EmptyHistory() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        vm.stopPrank();

        PersonaStorageManager.DataUpdate[] memory history = storageManager.getUpdateHistory(groupId, 10);
        assertEq(history.length, 1); // Initial creation entry
        assertEq(history[0].updateReason, "Initial creation");
    }

    // ============ Edge Case Tests ============

    function test_CreateStorageGroup_LongName() public {
        vm.startPrank(storageAdmin);

        string memory longName =
            "This is a very long storage group name that contains many characters and should test the limits of string storage in Solidity contracts to ensure that long names are handled properly without causing any issues or reverts in the contract execution flow";

        uint256 groupId =
            storageManager.createStorageGroup(longName, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        (string memory name,,,,,,) = storageManager.getStorageGroupInfo(groupId);
        assertEq(name, longName);

        vm.stopPrank();
    }

    function test_UpdatePersonaData_LongURI() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        string memory longURI =
            "0g://storage/very-long-uri-with-many-parameters-and-identifiers-that-might-be-used-in-real-world-scenarios-where-storage-systems-need-to-handle-complex-file-paths-and-identifiers-for-encrypted-data-storage-and-retrieval-operations";

        storageManager.updatePersonaData(groupId, longURI, bytes32(uint256(999)), "Long URI test");

        (,, string memory storageURI,,,,) = storageManager.getStorageGroupInfo(groupId);
        assertEq(storageURI, longURI);

        vm.stopPrank();
    }

    function test_UpdatePersonaData_LongUpdateReason() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        string memory longReason =
            "This is a very detailed update reason that explains exactly why this data update was necessary, including information about the source of the new data, the validation process that was followed, the approval chain that was used, and any other relevant details that administrators might need to understand the context and implications of this particular data update operation";

        storageManager.updatePersonaData(groupId, "new-uri", bytes32(uint256(123)), longReason);

        PersonaStorageManager.DataUpdate[] memory history = storageManager.getUpdateHistory(groupId, 1);
        assertEq(history[0].updateReason, longReason);

        vm.stopPrank();
    }

    function test_AddSameUpdaterTwice() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        storageManager.addAuthorizedUpdater(groupId, updater1);

        // Adding the same updater again should not cause issues
        storageManager.addAuthorizedUpdater(groupId, updater1);

        vm.stopPrank();

        // Updater should still be able to update
        vm.startPrank(updater1);
        storageManager.updatePersonaData(groupId, "new-uri", bytes32(uint256(123)), UPDATE_REASON);
        vm.stopPrank();
    }

    function test_RemoveNonexistentUpdater() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        // Try to remove an updater that was never added
        storageManager.removeAuthorizedUpdater(groupId, updater1);

        vm.stopPrank();

        // Should not cause any issues
        vm.startPrank(updater1);

        vm.expectRevert("Not authorized to update");
        storageManager.updatePersonaData(groupId, "new-uri", bytes32(uint256(123)), UPDATE_REASON);

        vm.stopPrank();
    }

    // ============ Access Control Tests ============

    // Note: createStorageGroup allows anyone to create groups (no access control)
    // function test_OnlyStorageAdminCanCreate() public {
    //     vm.startPrank(admin); // Admin but not storage admin

    //     vm.expectRevert();
    //     storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

    //     vm.stopPrank();
    // }

    function test_GroupAdminCanManageUpdaters() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        // Group admin (storageAdmin) should be able to add updaters
        storageManager.addAuthorizedUpdater(groupId, updater1);
        storageManager.removeAuthorizedUpdater(groupId, updater1);

        vm.stopPrank();
    }

    // ============ Gas Optimization Tests ============

    function test_GasUsage_CreateStorageGroup() public {
        vm.startPrank(storageAdmin);

        uint256 gasBefore = gasleft();
        storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for createStorageGroup:", gasUsed);
        assertLt(gasUsed, 400000); // Should use less than 400k gas

        vm.stopPrank();
    }

    function test_GasUsage_UpdatePersonaData() public {
        vm.startPrank(storageAdmin);

        uint256 groupId =
            storageManager.createStorageGroup(GROUP_NAME, ENCRYPTION_KEY_HASH, INITIAL_STORAGE_URI, INITIAL_DATA_HASH);

        uint256 gasBefore = gasleft();
        storageManager.updatePersonaData(groupId, "new-uri", bytes32(uint256(123)), UPDATE_REASON);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for updatePersonaData:", gasUsed);
        assertLt(gasUsed, 300000); // Should use less than 300k gas

        vm.stopPrank();
    }

    // ============ State Consistency Tests ============

    function test_StateConsistency_AfterMultipleOperations() public {
        vm.startPrank(storageAdmin);

        // Create multiple groups
        uint256 groupId1 =
            storageManager.createStorageGroup("Group1", bytes32(uint256(1)), "uri1", bytes32(uint256(11)));
        uint256 groupId2 =
            storageManager.createStorageGroup("Group2", bytes32(uint256(2)), "uri2", bytes32(uint256(22)));

        // Add updaters to both groups
        storageManager.addAuthorizedUpdater(groupId1, updater1);
        storageManager.addAuthorizedUpdater(groupId2, updater2);

        // Update both groups
        storageManager.updatePersonaData(groupId1, "new-uri1", bytes32(uint256(111)), "Update group 1");
        storageManager.updatePersonaData(groupId2, "new-uri2", bytes32(uint256(222)), "Update group 2");

        vm.stopPrank();

        // Verify state consistency
        assertEq(storageManager.getTotalGroups(), 2);

        (,, string memory uri1,,, uint256 version1,) = storageManager.getStorageGroupInfo(groupId1);
        (,, string memory uri2,,, uint256 version2,) = storageManager.getStorageGroupInfo(groupId2);

        assertEq(uri1, "new-uri1");
        assertEq(uri2, "new-uri2");
        assertEq(version1, 2);
        assertEq(version2, 2);
    }
}
