// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DiamondAccessControl} from "@solarity/solidity-lib/diamond/access/access-control/DiamondAccessControl.sol";

import {IAgentAccessControl} from "../interfaces/IAgentAccessControl.sol";

abstract contract AgentAccessControl is IAgentAccessControl, DiamondAccessControl {
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    function checkRole(bytes32 role_, address account_) public view virtual {
        _checkRole(role_, account_);
    }
}
