// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {AgentAccessControl} from "../../core/AgentAccessControl.sol";

contract AgentAccessControlMock is AgentAccessControl {
    function __AgentAccessControlMock_init() external initializer {
        __AgentAccessControl_init();
    }

    function __AgentAccessControlDirect_init() external {
        __AgentAccessControl_init();
    }
}
