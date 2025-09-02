// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IERC7857 is IERC721 {
    // Transfer with metadata re-encryption
    function transfer(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata sealedKey,
        bytes calldata proof
    ) external;
    
    // Clone token with same metadata
    function clone(
        address to,
        uint256 tokenId,
        bytes calldata sealedKey,
        bytes calldata proof
    ) external returns (uint256 newTokenId);
    
    // Authorize usage without revealing data
    function authorizeUsage(
        uint256 tokenId,
        address executor,
        bytes calldata permissions
    ) external;
}