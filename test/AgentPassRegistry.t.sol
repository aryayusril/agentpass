// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AgentPassRegistry} from "../src/AgentPassRegistry.sol";
import {MockAgentId} from "../src/MockAgentId.sol";

/// @dev Minimal cheatcode interface so tests run with zero external dependencies
///      (no forge-std download needed).
interface Vm {
    function prank(address msgSender) external;
}

contract AgentPassRegistryTest {
    Vm private constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    MockAgentId private agentId;
    AgentPassRegistry private registry;

    address private alice = address(0xA11CE);
    address private bob = address(0xB0B);
    address private stranger = address(0x57A9);

    function setUp() public {
        agentId = new MockAgentId();
        registry = new AgentPassRegistry(address(agentId));
        agentId.mint(alice);
        agentId.mint(bob);
        // `stranger` holds no Agent ID.
    }

    function _registerAs(address who, string memory name) internal {
        vm.prank(who);
        registry.register(name, "trading, research", "https://example.com/agent");
    }

    function test_HolderCanRegister() public {
        _registerAs(alice, "alice.ai");
        require(registry.isRegistered(alice), "alice should be registered");
        require(registry.totalAgents() == 1, "totalAgents should be 1");
        AgentPassRegistry.Profile memory p = registry.profileOf(alice);
        require(keccak256(bytes(p.agentName)) == keccak256(bytes("alice.ai")), "name mismatch");
    }

    function test_NonHolderCannotRegister() public {
        vm.prank(stranger);
        try registry.register("stranger.ai", "", "") {
            revert("non-holder registration should have reverted");
        } catch (bytes memory reason) {
            require(
                keccak256(reason) == keccak256(abi.encodeWithSignature("NotAgentIdHolder()")),
                "wrong revert reason"
            );
        }
        require(!registry.isRegistered(stranger), "stranger must not be registered");
    }

    function test_DoubleRegistrationReverts() public {
        _registerAs(alice, "alice.ai");
        vm.prank(alice);
        try registry.register("alice.ai", "", "") {
            revert("second registration should have reverted");
        } catch (bytes memory reason) {
            require(
                keccak256(reason) == keccak256(abi.encodeWithSignature("AlreadyRegistered()")),
                "wrong revert reason"
            );
        }
    }

    function test_EndorseFlow() public {
        _registerAs(alice, "alice.ai");
        _registerAs(bob, "bob.ai");

        vm.prank(alice);
        registry.endorse(bob);
        require(registry.endorsementCountOf(bob) == 1, "bob should have 1 endorsement");
        require(registry.endorsements(alice, bob), "endorsement flag missing");

        // second endorsement from the same pair must revert
        vm.prank(alice);
        try registry.endorse(bob) {
            revert("duplicate endorsement should have reverted");
        } catch (bytes memory reason) {
            require(
                keccak256(reason) == keccak256(abi.encodeWithSignature("AlreadyEndorsed()")),
                "wrong revert reason"
            );
        }
    }

    function test_UnregisteredCannotEndorse() public {
        _registerAs(bob, "bob.ai");
        vm.prank(alice); // alice holds an Agent ID but never registered
        try registry.endorse(bob) {
            revert("unregistered endorser should have reverted");
        } catch (bytes memory reason) {
            require(
                keccak256(reason) == keccak256(abi.encodeWithSignature("NotRegistered()")),
                "wrong revert reason"
            );
        }
    }

    function test_UpdateProfile() public {
        _registerAs(alice, "alice.ai");
        vm.prank(alice);
        registry.updateProfile("payments, x402", "https://alice.example.com");
        AgentPassRegistry.Profile memory p = registry.profileOf(alice);
        require(keccak256(bytes(p.capabilities)) == keccak256(bytes("payments, x402")), "capabilities not updated");
    }
}
