// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract KYCComplianceStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 internal constant KYC_COMPLIANCE_STORAGE_SLOT =
        keccak256("tokenf.standard.kyc.compliance.storage");

    struct KYCCStorage {
        EnumerableSet.AddressSet kycModules;
    }

    function getKYCModules() public view virtual returns (address[] memory) {
        return _getKYCComplianceStorage().kycModules.values();
    }

    function getKYCModulesCount() public view virtual returns (uint256) {
        return _getKYCComplianceStorage().kycModules.length();
    }

    function _getKYCComplianceStorage() internal pure returns (KYCCStorage storage _kyccStorage) {
        bytes32 slot_ = KYC_COMPLIANCE_STORAGE_SLOT;

        assembly {
            _kyccStorage.slot := slot_
        }
    }
}
