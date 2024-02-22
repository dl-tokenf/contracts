// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract RegulatoryComplianceStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 internal constant REGULATORY_COMPLIANCE_STORAGE_SLOT =
        keccak256("tokenf.standard.regulatory.compliance.storage");

    struct RCStorage {
        EnumerableSet.AddressSet regulatoryModules;
    }

    function getRegulatoryModules() public view returns (address[] memory) {
        return _getRegulatoryComplianceStorage().regulatoryModules.values();
    }

    function getRegulatoryModulesCount() public view virtual returns (uint256) {
        return _getRegulatoryComplianceStorage().regulatoryModules.length();
    }

    function _getRegulatoryComplianceStorage()
        internal
        pure
        returns (RCStorage storage _rcStorage)
    {
        bytes32 slot_ = REGULATORY_COMPLIANCE_STORAGE_SLOT;

        assembly {
            _rcStorage.slot := slot_
        }
    }
}
