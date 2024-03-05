// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IKYCCompliance {
    function addKYCModules(address[] memory kycModules_) external;

    function removeKYCModules(address[] memory kycModules_) external;

    function isKYCed(
        bytes4 selector_,
        address from_,
        address to_,
        uint256 amount_,
        address operator_,
        bytes memory data_
    ) external view returns (bool);
}
