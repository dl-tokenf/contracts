// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {KYCCompliance} from "../../core/KYCCompliance.sol";

contract KYCComplianceMock is KYCCompliance {
    bytes32 public constant KYC_COMPLIANCE_ROLE = keccak256("KYC_COMPLIANCE_ROLE");

    function __KYCComplianceMock_init() external initializer {
        __KYCCompliance_init();
    }

    function __KYCComplianceDirect_init() external {
        __KYCCompliance_init();
    }

    function defaultKYCComplianceRole() external view returns (bytes32) {
        return super._KYCComplianceRole();
    }

    function _KYCComplianceRole() internal pure override returns (bytes32) {
        return KYC_COMPLIANCE_ROLE;
    }
}
