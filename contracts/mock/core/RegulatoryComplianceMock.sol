// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegulatoryCompliance} from "../../core/RegulatoryCompliance.sol";

contract RegulatoryComplianceMock is RegulatoryCompliance {
    bytes32 public constant REGULATORY_COMPLIANCE_ROLE = keccak256("REGULATORY_COMPLIANCE_ROLE");

    function __RegulatoryComplianceMock_init()
        external
        initializer(REGULATORY_COMPLIANCE_STORAGE_SLOT)
    {
        __RegulatoryCompliance_init();
    }

    function __RegulatoryComplianceDirect_init() external {
        __RegulatoryCompliance_init();
    }

    function defaultRegulatoryComplianceRole() external view returns (bytes32) {
        return super._regulatoryComplianceRole();
    }

    function _regulatoryComplianceRole() internal pure override returns (bytes32) {
        return REGULATORY_COMPLIANCE_ROLE;
    }
}
