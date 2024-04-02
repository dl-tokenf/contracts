// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @notice The `IRegulatoryComplianceView` interface stores all the view functions that are in the `RegulatoryCompliance` contract
 */
interface IRegulatoryComplianceView {
    /**
     * @notice Function to get the total number of regulatory modules,
     * that are currently added to the list of `RegulatoryCompliance` contract modules
     *
     * @return Total number of all regulatory modules in the `RegulatoryCompliance` contract
     */
    function getRegulatoryModulesCount() external view returns (uint256);

    /**
     * @notice Function to get a list of addresses of all regulatory modules,
     * that are currently added to the list of `RegulatoryCompliance` contract modules
     *
     * @return Array of addresses of all regulatory modules in the `RegulatoryCompliance` contract
     */
    function getRegulatoryModules() external view returns (address[] memory);
}
