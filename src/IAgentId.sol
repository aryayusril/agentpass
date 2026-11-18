// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal read interface for the SPACE ID Agent ID NFT on BNB Chain.
/// @dev Mainnet contract: 0x60b9262456de011f7d15a54cdd8c48baaa8b022f
///      (SPACE ID Agent ID, symbol "AI", ERC-721, non-transferable).
///      Per the official Binance announcement, balanceOf(address) > 0 means
///      the address holds an Agent ID.
interface IAgentId {
    function balanceOf(address owner) external view returns (uint256);
}
