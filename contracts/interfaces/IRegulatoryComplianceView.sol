// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRegulatoryComplianceView {
    function getRegulatoryModulesCount() external view returns (uint256);

    function getRegulatoryModules() external view returns (address[] memory);
}
