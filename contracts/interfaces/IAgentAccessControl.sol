// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAgentAccessControl {
    function checkRole(bytes32 role_, address account_) external view;

    function getAgentRole() external view returns (bytes32);
}
