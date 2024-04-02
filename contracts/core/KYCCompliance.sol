// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SetHelper} from "@solarity/solidity-lib/libs/arrays/SetHelper.sol";

import {IKYCCompliance} from "../interfaces/IKYCCompliance.sol";

import {AgentAccessControl} from "./AgentAccessControl.sol";
import {TokenF} from "./TokenF.sol";
import {KYCComplianceStorage} from "./storages/KYCComplianceStorage.sol";

import {AbstractKYCModule} from "../modules/AbstractKYCModule.sol";

/**
 * @notice The KYCCompliance contract
 *
 * The KYCCompliance is a core contract that serves as a repository for KYC modules.
 * It tracks every transfer made within the TokenF contract and disseminates its context to registered KYC modules.
 */
abstract contract KYCCompliance is IKYCCompliance, KYCComplianceStorage, AgentAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SetHelper for EnumerableSet.AddressSet;

    function __KYCCompliance_init() internal onlyInitializing(KYC_COMPLIANCE_STORAGE_SLOT) {}

    /// @inheritdoc IKYCCompliance
    function addKYCModules(
        address[] memory kycModules_
    ) public virtual onlyRole(_KYCComplianceRole()) {
        _addKYCModules(kycModules_);
    }

    /// @inheritdoc IKYCCompliance
    function removeKYCModules(
        address[] memory kycModules_
    ) public virtual onlyRole(_KYCComplianceRole()) {
        _removeKYCModules(kycModules_);
    }

    /// @inheritdoc IKYCCompliance
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
        _getKYCComplianceStorage().kycModules.strictAdd(kycModules_);
    }

    function _removeKYCModules(address[] memory kycModules_) internal virtual {
        _getKYCComplianceStorage().kycModules.strictRemove(kycModules_);
    }

    function _KYCComplianceRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }
}
