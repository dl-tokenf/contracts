// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IKYCComplianceView} from "../../interfaces/IKYCComplianceView.sol";

abstract contract KYCComplianceStorage is IKYCComplianceView {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 internal constant KYC_COMPLIANCE_STORAGE_SLOT =
        keccak256("tokenf.standard.kyc.compliance.storage");

    struct KYCCStorage {
        EnumerableSet.AddressSet kycModules;
    }

    /// @inheritdoc IKYCComplianceView
    function getKYCModulesCount() public view virtual override returns (uint256) {
        return _getKYCComplianceStorage().kycModules.length();
    }

    /// @inheritdoc IKYCComplianceView
    function getKYCModules() public view virtual override returns (address[] memory) {
        return _getKYCComplianceStorage().kycModules.values();
    }

    function _getKYCComplianceStorage() internal pure returns (KYCCStorage storage _kyccStorage) {
        bytes32 slot_ = KYC_COMPLIANCE_STORAGE_SLOT;

        assembly {
            _kyccStorage.slot := slot_
        }
    }
}
