// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IKYCComplianceView {
    function getKYCModulesCount() external view returns (uint256);

    function getKYCModules() external view returns (address[] memory);
}
