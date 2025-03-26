// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IAgentAccessControl} from "../interfaces/IAgentAccessControl.sol";

import {AgentAccessControlStorage} from "./storages/AgentAccessControlStorage.sol";

/**
 * @notice The AgentAccessControl contract
 *
 * The AgentAccessControl is a core contract that serves as a foundational component for managing roles.
 * Every core contract or other system module should inherit or integrate it respectfully to ensure consistent access permissions across the system.
 */
abstract contract AgentAccessControl is
    IAgentAccessControl,
    AgentAccessControlStorage,
    AccessControlUpgradeable
{
    /// @inheritdoc IAgentAccessControl
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    function __AgentAccessControl_init() internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        grantRole(AGENT_ROLE, msg.sender);
    }

    /// @inheritdoc IAgentAccessControl
    function checkRole(bytes32 role_, address account_) public view virtual {
        _checkRole(role_, account_);
    }
}
