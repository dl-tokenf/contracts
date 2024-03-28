// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IKYCComplianceView} from "./IKYCComplianceView.sol";

import {TokenF} from "../core/TokenF.sol";

interface IKYCCompliance is IKYCComplianceView {
    function addKYCModules(address[] memory kycModules_) external;

    function removeKYCModules(address[] memory kycModules_) external;

    function isKYCed(TokenF.Context calldata ctx_) external view returns (bool);
}
