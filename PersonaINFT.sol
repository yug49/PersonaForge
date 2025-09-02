// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This is the main PersonaINFT implementation
// For the complete implementation, see contracts/src/PersonaINFT.sol

/**
 * @title PersonaForge INFT System
 * @dev Complete implementation of Intelligent NFTs for AI agents
 *
 * This file serves as the main entry point and exports all contracts.
 * The actual implementations are in the contracts/src/ directory.
 *
 * Key Components:
 * - PersonaINFT: Main NFT contract with agent access control
 * - PersonaStorageManager: Central encrypted storage management
 * - PersonaAgentManager: AI agent interaction and configuration
 *
 * Features:
 * - Agent access control (not data transfer)
 * - Central admin-controlled storage
 * - Simple NFT transfers without re-encryption
 * - 0G Infrastructure integration
 *
 * Usage:
 * 1. Deploy all three contracts using contracts/script/Deploy.s.sol
 * 2. Configure roles and permissions
 * 3. Create persona groups and storage
 * 4. Mint INFTs for users
 * 5. Users interact with AI agents through their INFTs
 *
 * See PersonaINFT_Documentation.md for detailed usage instructions.
 *
 * Quick Start:
 * ```bash
 * # Build contracts
 * forge build
 *
 * # Deploy to 0G testnet
 * forge script contracts/script/Deploy.s.sol --rpc-url og_testnet --broadcast
 *
 * # Run example usage
 * forge script contracts/script/ExampleUsage.s.sol --rpc-url og_testnet --broadcast
 * ```
 */

// Import statements for reference (actual contracts are in contracts/src/)
// import "./contracts/src/PersonaINFT.sol";
// import "./contracts/src/PersonaStorageManager.sol";
// import "./contracts/src/PersonaAgentManager.sol";
