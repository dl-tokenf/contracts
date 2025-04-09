// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

abstract contract AgentAccessControlStorage {
    bytes32 internal constant AGENT_ACCESS_CONTROL_STORAGE_SLOT =
        keccak256("tokenf.standard.agent.access.control.storage");
}
