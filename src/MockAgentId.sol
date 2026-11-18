// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice TEST-ONLY stand-in for the SPACE ID Agent ID NFT.
///         Lets the registry be developed and tested locally without mainnet.
///         Never deploy this to mainnet as part of the product: the real gate
///         is the official contract 0x60b9262456de011f7d15a54cdd8c48baaa8b022f.
contract MockAgentId {
    mapping(address => uint256) private _balances;

    function mint(address to) external {
        _balances[to] += 1;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
}
