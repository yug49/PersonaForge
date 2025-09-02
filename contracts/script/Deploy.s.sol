// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PersonaINFT.sol";
import "../src/PersonaStorageManager.sol";
import "../src/PersonaAgentManager.sol";

/**
 * @title Deploy
 * @dev Deployment script for PersonaForge INFT system
 */
contract Deploy is Script {
    // Configuration
    string constant NAME = "PersonaForge INFTs";
    string constant SYMBOL = "PINFT";

    // 0G Infrastructure addresses (testnet)
    address constant OG_STORAGE_ADDRESS = 0x1000000000000000000000000000000000000001; // Placeholder
    address constant OG_COMPUTE_ADDRESS = 0x2000000000000000000000000000000000000002; // Placeholder

    // Central server configuration
    string constant CENTRAL_SERVER_PUBLIC_KEY = "-----BEGIN PUBLIC KEY-----...-----END PUBLIC KEY-----"; // Placeholder
    string constant AGENT_MODEL_ENDPOINT = "https://compute-testnet.0g.ai/v1/agent/inference";

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying PersonaForge INFT system...");
        console.log("Deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy PersonaStorageManager
        console.log("Deploying PersonaStorageManager...");
        PersonaStorageManager storageManager = new PersonaStorageManager(OG_STORAGE_ADDRESS, CENTRAL_SERVER_PUBLIC_KEY);
        console.log("PersonaStorageManager deployed at:", address(storageManager));

        // 2. Deploy PersonaINFT
        console.log("Deploying PersonaINFT...");
        PersonaINFT personaINFT = new PersonaINFT(NAME, SYMBOL, OG_STORAGE_ADDRESS, OG_COMPUTE_ADDRESS);
        console.log("PersonaINFT deployed at:", address(personaINFT));

        // 3. Deploy PersonaAgentManager
        console.log("Deploying PersonaAgentManager...");
        PersonaAgentManager agentManager = new PersonaAgentManager(
            address(personaINFT), address(storageManager), OG_COMPUTE_ADDRESS, AGENT_MODEL_ENDPOINT
        );
        console.log("PersonaAgentManager deployed at:", address(agentManager));

        // 4. Configure contracts
        console.log("Configuring contracts...");

        // Grant roles
        bytes32 adminRole = personaINFT.ADMIN_ROLE();
        personaINFT.grantRole(adminRole, deployer);

        bytes32 groupAdminRole = personaINFT.GROUP_ADMIN_ROLE();
        personaINFT.grantRole(groupAdminRole, deployer);

        // Configure agent manager
        agentManager.addAuthorizedCaller(address(personaINFT));

        vm.stopBroadcast();

        console.log("=== Deployment Summary ===");
        console.log("PersonaStorageManager:", address(storageManager));
        console.log("PersonaINFT:", address(personaINFT));
        console.log("PersonaAgentManager:", address(agentManager));
        console.log("=========================");

        // Save deployment addresses
        string memory deploymentInfo = string(
            abi.encodePacked(
                "PersonaStorageManager=",
                vm.toString(address(storageManager)),
                "\n",
                "PersonaINFT=",
                vm.toString(address(personaINFT)),
                "\n",
                "PersonaAgentManager=",
                vm.toString(address(agentManager)),
                "\n"
            )
        );

        vm.writeFile("deployment-addresses.txt", deploymentInfo);
        console.log("Deployment addresses saved to deployment-addresses.txt");
    }
}
