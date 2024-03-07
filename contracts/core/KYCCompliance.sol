// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IKYCCompliance} from "../interfaces/IKYCCompliance.sol";

import {AgentAccessControl} from "./AgentAccessControl.sol";
import {TokenF} from "./TokenF.sol";
import {KYCComplianceStorage} from "./storages/KYCComplianceStorage.sol";

import {AbstractKYCModule} from "../modules/AbstractKYCModule.sol";

abstract contract KYCCompliance is IKYCCompliance, KYCComplianceStorage, AgentAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    function __KYCCompliance_init() internal onlyInitializing(KYC_COMPLIANCE_STORAGE_SLOT) {}

    function addKYCModules(
        address[] memory kycModules_
    ) public virtual onlyRole(_KYCComplianceRole()) {
        _addKYCModules(kycModules_);
    }

    function removeKYCModules(
        address[] memory kycModules_
    ) public virtual onlyRole(_KYCComplianceRole()) {
        _removeKYCModules(kycModules_);
    }

    function isKYCed(TokenF.Context calldata ctx_) public view virtual returns (bool) {
        address[] memory regulatoryModules_ = getKYCModules();

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            if (!AbstractKYCModule(regulatoryModules_[i]).isKYCed(ctx_)) {
                return false;
            }
        }

        return true;
    }

    function _addKYCModules(address[] memory kycModules_) internal virtual {
        EnumerableSet.AddressSet storage _kycModules = _getKYCComplianceStorage().kycModules;

        for (uint256 i = 0; i < kycModules_.length; ++i) {
            require(_kycModules.add(kycModules_[i]), "KYCCompliance: module exists");
        }
    }

    function _removeKYCModules(address[] memory kycModules_) internal virtual {
        EnumerableSet.AddressSet storage _kycModules = _getKYCComplianceStorage().kycModules;

        for (uint256 i = 0; i < kycModules_.length; ++i) {
            require(_kycModules.remove(kycModules_[i]), "KYCCompliance: module doesn't exist");
        }
    }

    function _KYCComplianceRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }
}
