// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @notice `IKYCComplianceView` interface stores all view functions that are in the `KYCCompliance` contract
 */
interface IKYCComplianceView {
    /**
     * @notice Function to get the total number of KYC modules,
     * that are currently added to the list of `KYCCompliance` contract modules
     *
     * @return Total number of all KYC modules in the `KYCCompliance` contract
     */
    function getKYCModulesCount() external view returns (uint256);

    /**
     * @notice Function to get the address list of all KYC modules,
     * that are currently added to the list of `KYCCompliance` contract modules
     *
     * @return Array of addresses of all KYC modules in the `KYCCompliance` contract
     */
    function getKYCModules() external view returns (address[] memory);
}
