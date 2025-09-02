// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PersonaINFT.sol";
import "../src/PersonaStorageManager.sol";
import "../src/PersonaAgentManager.sol";

/**
 * @title ExampleUsage
 * @dev Example script demonstrating PersonaForge INFT usage
 */
contract ExampleUsage is Script {
    // Contract addresses (to be loaded from deployment)
    PersonaINFT personaINFT;
    PersonaStorageManager storageManager;
    PersonaAgentManager agentManager;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load deployed contract addresses
        address personaINFTAddress = vm.envAddress("PERSONA_INFT_ADDRESS");
        address storageManagerAddress = vm.envAddress("STORAGE_MANAGER_ADDRESS");
        address agentManagerAddress = vm.envAddress("AGENT_MANAGER_ADDRESS");

        personaINFT = PersonaINFT(personaINFTAddress);
        storageManager = PersonaStorageManager(storageManagerAddress);
        agentManager = PersonaAgentManager(agentManagerAddress);

        console.log("=== PersonaForge INFT Example Usage ===");
        console.log("PersonaINFT:", address(personaINFT));
        console.log("StorageManager:", address(storageManager));
        console.log("AgentManager:", address(agentManager));

        vm.startBroadcast(deployerPrivateKey);

        // Example 1: Create a storage group for AI agent data
        console.log("\n1. Creating storage group...");

        bytes32 encryptionKeyHash = keccak256("example-encryption-key-hash");
        string memory storageURI = "0g://storage/persona-data-example-123";
        bytes32 dataHash = keccak256("encrypted-persona-data");

        uint256 groupId =
            storageManager.createStorageGroup("AI Assistant Persona", encryptionKeyHash, storageURI, dataHash);

        console.log("Storage group created with ID:", groupId);

        // Example 2: Create a persona group linked to the storage
        console.log("\n2. Creating persona group...");

        uint256 personaGroupId = personaINFT.createPersonaGroup(
            "AI Assistant Persona", "A helpful AI assistant with expertise in various domains", storageURI, dataHash
        );

        console.log("Persona group created with ID:", personaGroupId);

        // Example 3: Mint PersonaINFTs for different users
        console.log("\n3. Minting PersonaINFTs...");

        // Mint for deployer
        uint256 tokenId1 =
            personaINFT.mintPersonaINFT(deployer, personaGroupId, "Helpful, professional, detail-oriented");
        console.log("TokenId 1 minted for deployer:", tokenId1);

        // Create a second user address for example
        address user2 = address(0x1234567890123456789012345678901234567890);

        uint256 tokenId2 = personaINFT.mintPersonaINFT(user2, personaGroupId, "Creative, enthusiastic, innovative");
        console.log("TokenId 2 minted for user2:", tokenId2);

        // Example 4: Configure agent for the tokens
        console.log("\n4. Configuring AI agents...");

        IPersonaAgent.PersonaConfig memory config1 = IPersonaAgent.PersonaConfig({
            name: "Alex - Professional Assistant",
            description: "A professional AI assistant focused on productivity",
            personalityTraits: "Helpful, professional, detail-oriented, efficient",
            knowledgeBase: storageURI,
            isActive: true
        });

        agentManager.updatePersonaConfig(tokenId1, config1);
        console.log("Agent configured for token:", tokenId1);

        // Example 5: Simulate agent interaction
        console.log("\n5. Testing agent interaction...");

        // Check if user has access
        bool hasAccess = agentManager.hasAgentAccess(tokenId1, deployer);
        console.log("Deployer has access to token 1:", hasAccess);

        // Simulate interaction (would normally be called by PersonaINFT contract)
        if (hasAccess) {
            // Note: Agent interaction would normally be called through PersonaINFT.interactWithAgent()
            // IPersonaAgent.AgentRequest memory request = IPersonaAgent.AgentRequest({
            //     tokenId: tokenId1,
            //     requester: deployer,
            //     query: "Hello, can you help me with project planning?",
            //     timestamp: block.timestamp,
            //     context: abi.encode("project_planning", "business")
            // });
            // IPersonaAgent.AgentResponse memory response = agentManager.processQuery(request);
            // console.log("Agent response:", response.response);

            console.log("Agent interaction test prepared (would be executed via PersonaINFT)");
        }

        // Example 6: Update storage group data (admin only)
        console.log("\n6. Updating persona data...");

        string memory newStorageURI = "0g://storage/persona-data-updated-456";
        bytes32 newDataHash = keccak256("updated-encrypted-persona-data");

        storageManager.updatePersonaData(
            groupId, newStorageURI, newDataHash, "Added new training data and improved responses"
        );

        console.log("Storage group updated with new data");

        // Example 7: Update persona group to reflect new data
        personaINFT.updatePersonaGroup(personaGroupId, newStorageURI, newDataHash);

        console.log("Persona group updated with new data");

        // Example 8: Transfer a PersonaINFT
        console.log("\n7. Transferring PersonaINFT...");

        // Transfer token 1 to user2
        personaINFT.transferFrom(deployer, user2, tokenId1);

        // Verify new owner
        address newOwner = personaINFT.ownerOf(tokenId1);
        console.log("Token 1 transferred to:", newOwner);
        console.log("Transfer successful:", newOwner == user2);

        // Example 9: Check access after transfer
        console.log("\n8. Verifying access after transfer...");

        bool oldOwnerAccess = agentManager.hasAgentAccess(tokenId1, deployer);
        bool newOwnerAccess = agentManager.hasAgentAccess(tokenId1, user2);

        console.log("Original owner still has access:", oldOwnerAccess);
        console.log("New owner has access:", newOwnerAccess);

        // Example 10: Get contract information
        console.log("\n9. Contract information...");

        console.log("Total storage groups:", storageManager.getTotalGroups());

        uint256[] memory user2Tokens = personaINFT.getUserTokens(user2);
        console.log("User2 token count:", user2Tokens.length);

        uint256[] memory groupTokens = personaINFT.getGroupTokens(personaGroupId);
        console.log("Tokens in persona group:", groupTokens.length);

        vm.stopBroadcast();

        console.log("\n=== Example Usage Complete ===");
        console.log("PersonaForge INFT system successfully demonstrated!");
        console.log("Key features shown:");
        console.log("- Central storage management");
        console.log("- PersonaINFT minting and transfer");
        console.log("- AI agent configuration");
        console.log("- Access control based on NFT ownership");
        console.log("- Data updates without affecting NFT transfers");
    }
}
