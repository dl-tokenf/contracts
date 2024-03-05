// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAgentAccessControl {
    function AGENT_ROLE() external view returns (bytes32);

    function checkRole(bytes32 role_, address account_) external view;
}
