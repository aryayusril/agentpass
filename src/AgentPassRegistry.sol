// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAgentId} from "./IAgentId.sol";

/// @title AgentPass Registry
/// @notice An on-chain directory and trust registry that ONLY Agent ID holders can join.
///         Holding an Agent ID (name.ai) is the identity layer of the whole product:
///         - registration is gated by the Agent ID NFT (access control),
///         - your public agent profile is keyed to the wallet that holds your Agent ID (identity),
///         - endorsements between registered agents form an on-chain reputation graph (trust).
///
///         The contract never takes custody of user assets. The only thing a user
///         spends is their own gas. There are no fees, no escrow, no approvals.
///
///         Owner permissions (disclosed per hackathon rules): the contract has NO owner,
///         NO mint function, NO pause, NO freeze, NO withdrawal function. It is fully
///         permissionless and immutable after deployment. Anyone can verify this in the
///         verified source code.
contract AgentPassRegistry {
    /// @notice The Agent ID NFT contract used as the identity gate.
    IAgentId public immutable agentId;

    struct Profile {
        string agentName; // self-declared Agent ID name, e.g. "zeroname.ai"
        string capabilities; // short free-text list of what the agent can do
        string endpoint; // public contact / service endpoint URI chosen by the agent
        uint256 registeredAt; // block timestamp of registration
        bool exists;
    }

    mapping(address => Profile) private _profiles;
    address[] private _agents;

    /// @dev endorsements[from][to] == true if `from` has endorsed `to`.
    mapping(address => mapping(address => bool)) public endorsements;
    mapping(address => uint256) private _endorsementCounts;

    event Registered(address indexed agent, string agentName);
    event ProfileUpdated(address indexed agent);
    event Endorsed(address indexed from, address indexed to);

    error NotAgentIdHolder();
    error AlreadyRegistered();
    error NotRegistered();
    error CannotEndorseSelf();
    error AlreadyEndorsed();
    error EmptyName();

    constructor(address agentIdContract) {
        agentId = IAgentId(agentIdContract);
    }

    /// @notice True if `account` currently holds an Agent ID.
    function isAgentIdHolder(address account) public view returns (bool) {
        return agentId.balanceOf(account) > 0;
    }

    /// @notice Register your agent profile. Caller must hold an Agent ID.
    /// @dev One profile per address. The profile is the agent's public business
    ///      card: it only contains data the agent itself chose to publish.
    function register(string calldata agentName, string calldata capabilities, string calldata endpoint) external {
        if (!isAgentIdHolder(msg.sender)) revert NotAgentIdHolder();
        if (_profiles[msg.sender].exists) revert AlreadyRegistered();
        if (bytes(agentName).length == 0) revert EmptyName();

        _profiles[msg.sender] = Profile({
            agentName: agentName,
            capabilities: capabilities,
            endpoint: endpoint,
            registeredAt: block.timestamp,
            exists: true
        });
        _agents.push(msg.sender);
        emit Registered(msg.sender, agentName);
    }

    /// @notice Update your own profile fields. Only the profile owner can call
    ///         this for their own address (msg.sender IS the profile key).
    function updateProfile(string calldata capabilities, string calldata endpoint) external {
        if (!_profiles[msg.sender].exists) revert NotRegistered();
        _profiles[msg.sender].capabilities = capabilities;
        _profiles[msg.sender].endpoint = endpoint;
        emit ProfileUpdated(msg.sender);
    }

    /// @notice Endorse another registered agent. Both parties must be registered
    ///         Agent ID holders; one endorsement per pair. Endorsements are the
    ///         reputation layer: they are public, cost only gas, and move no assets.
    function endorse(address agent) external {
        if (!_profiles[msg.sender].exists) revert NotRegistered();
        if (!_profiles[agent].exists) revert NotRegistered();
        if (agent == msg.sender) revert CannotEndorseSelf();
        if (endorsements[msg.sender][agent]) revert AlreadyEndorsed();

        endorsements[msg.sender][agent] = true;
        _endorsementCounts[agent] += 1;
        emit Endorsed(msg.sender, agent);
    }

    // ---------- Views ----------

    function isRegistered(address account) external view returns (bool) {
        return _profiles[account].exists;
    }

    function profileOf(address account) external view returns (Profile memory) {
        return _profiles[account];
    }

    function endorsementCountOf(address account) external view returns (uint256) {
        return _endorsementCounts[account];
    }

    function totalAgents() external view returns (uint256) {
        return _agents.length;
    }

    function agentAt(uint256 index) external view returns (address) {
        return _agents[index];
    }
}
