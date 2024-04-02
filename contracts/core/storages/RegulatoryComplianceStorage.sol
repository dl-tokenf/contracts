// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IRegulatoryComplianceView} from "../../interfaces/IRegulatoryComplianceView.sol";

abstract contract RegulatoryComplianceStorage is IRegulatoryComplianceView {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 internal constant REGULATORY_COMPLIANCE_STORAGE_SLOT =
        keccak256("tokenf.standard.regulatory.compliance.storage");

    struct RCStorage {
        EnumerableSet.AddressSet regulatoryModules;
    }

    /// @inheritdoc IRegulatoryComplianceView
    function getRegulatoryModulesCount() public view virtual override returns (uint256) {
        return _getRegulatoryComplianceStorage().regulatoryModules.length();
    }

    /// @inheritdoc IRegulatoryComplianceView
    function getRegulatoryModules() public view virtual override returns (address[] memory) {
        return _getRegulatoryComplianceStorage().regulatoryModules.values();
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
