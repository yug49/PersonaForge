// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PersonaINFT.sol";
import "../src/PersonaStorageManager.sol";
import "../src/PersonaAgentManager.sol";

/**
 * @title SimpleDeploy
 * @dev Simplified deployment script for PersonaForge INFT system
 */
contract SimpleDeploy is Script {
    // Configuration
    string constant NAME = "PersonaForge INFTs";
    string constant SYMBOL = "PINFT";

    // 0G Infrastructure addresses (testnet placeholders)
    address constant OG_STORAGE_ADDRESS = 0x1111111111111111111111111111111111111111;
    address constant OG_COMPUTE_ADDRESS = 0x2222222222222222222222222222222222222222;

    // Central server configuration
    string constant CENTRAL_SERVER_PUBLIC_KEY =
        "-----BEGIN PUBLIC KEY-----MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...-----END PUBLIC KEY-----";
    string constant AGENT_MODEL_ENDPOINT = "https://compute-testnet.0g.ai/v1/agent/inference";

    function run() external {
        address deployer = msg.sender;

        console.log("=== PersonaForge INFT Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Network: 0G Newton Testnet");
        console.log("");

        vm.startBroadcast();

        // 1. Deploy PersonaStorageManager
        console.log("1. Deploying PersonaStorageManager...");
        PersonaStorageManager storageManager = new PersonaStorageManager(OG_STORAGE_ADDRESS, CENTRAL_SERVER_PUBLIC_KEY);
        console.log("   PersonaStorageManager deployed at:", address(storageManager));
        console.log("");

        // 2. Deploy PersonaINFT
        console.log("2. Deploying PersonaINFT...");
        PersonaINFT personaINFT = new PersonaINFT(NAME, SYMBOL, OG_STORAGE_ADDRESS, OG_COMPUTE_ADDRESS);
        console.log("   PersonaINFT deployed at:", address(personaINFT));
        console.log("");

        // 3. Deploy PersonaAgentManager
        console.log("3. Deploying PersonaAgentManager...");
        PersonaAgentManager agentManager = new PersonaAgentManager(
            address(personaINFT), address(storageManager), OG_COMPUTE_ADDRESS, AGENT_MODEL_ENDPOINT
        );
        console.log("   PersonaAgentManager deployed at:", address(agentManager));
        console.log("");

        // 4. Configure contracts
        console.log("4. Configuring contracts...");

        // Grant roles
        bytes32 adminRole = personaINFT.ADMIN_ROLE();
        personaINFT.grantRole(adminRole, deployer);

        bytes32 groupAdminRole = personaINFT.GROUP_ADMIN_ROLE();
        personaINFT.grantRole(groupAdminRole, deployer);

        // Configure agent manager
        agentManager.addAuthorizedCaller(address(personaINFT));

        console.log("   Configuration complete!");
        console.log("");

        vm.stopBroadcast();

        console.log("=== Deployment Summary ===");
        console.log("PersonaStorageManager:", address(storageManager));
        console.log("PersonaINFT:", address(personaINFT));
        console.log("PersonaAgentManager:", address(agentManager));
        console.log("");
        console.log("=== Environment Variables for .env ===");
        console.log("REACT_APP_PERSONA_INFT_ADDRESS=", address(personaINFT));
        console.log("REACT_APP_STORAGE_MANAGER_ADDRESS=", address(storageManager));
        console.log("REACT_APP_AGENT_MANAGER_ADDRESS=", address(agentManager));
        console.log("=========================");
    }
}
