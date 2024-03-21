// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAccessControl} from "@solarity/solidity-lib/diamond/access/access-control/DiamondAccessControl.sol";

interface IAgentAccessControl is IAccessControl {
    function AGENT_ROLE() external view returns (bytes32);

    function checkRole(bytes32 role_, address account_) external view;
}
