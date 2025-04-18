// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Diamond} from "@solarity/solidity-lib/diamond/Diamond.sol";

import {IAssetF} from "./interfaces/IAssetF.sol";
import {IKYCCompliance} from "./interfaces/core/IKYCCompliance.sol";
import {IRegulatoryCompliance} from "./interfaces/core/IRegulatoryCompliance.sol";

import {AgentAccessControl} from "./core/AgentAccessControl.sol";
import {RegulatoryComplianceStorage} from "./storages/core/RegulatoryComplianceStorage.sol";
import {KYCComplianceStorage} from "./storages/core/KYCComplianceStorage.sol";

abstract contract AbstractAssetF is IAssetF, Diamond, AgentAccessControl {
    bytes4 public constant RECOVERY_SELECTOR = this.recovery.selector;

    function __AbstractAssetF_init(
        address regulatoryCompliance_,
        address kycCompliance_,
        bytes memory initRegulatory_,
        bytes memory initKYC_
    ) internal virtual onlyInitializing {
        bytes4[] memory rComplianceSelectors_ = new bytes4[](6);
        rComplianceSelectors_[0] = IRegulatoryCompliance.addRegulatoryModules.selector;
        rComplianceSelectors_[1] = IRegulatoryCompliance.removeRegulatoryModules.selector;
        rComplianceSelectors_[2] = IRegulatoryCompliance.transferred.selector;
        rComplianceSelectors_[3] = IRegulatoryCompliance.canTransfer.selector;
        rComplianceSelectors_[4] = RegulatoryComplianceStorage.getRegulatoryModules.selector;
        rComplianceSelectors_[5] = RegulatoryComplianceStorage.getRegulatoryModulesCount.selector;

        bytes4[] memory kycComplianceSelectors_ = new bytes4[](5);
        kycComplianceSelectors_[0] = IKYCCompliance.addKYCModules.selector;
        kycComplianceSelectors_[1] = IKYCCompliance.removeKYCModules.selector;
        kycComplianceSelectors_[2] = IKYCCompliance.isKYCed.selector;
        kycComplianceSelectors_[3] = KYCComplianceStorage.getKYCModules.selector;
        kycComplianceSelectors_[4] = KYCComplianceStorage.getKYCModulesCount.selector;

        Facet[] memory facets_ = new Facet[](2);
        facets_[0] = Facet(regulatoryCompliance_, FacetAction.Add, rComplianceSelectors_);
        facets_[1] = Facet(kycCompliance_, FacetAction.Add, kycComplianceSelectors_);

        _diamondCut(facets_, address(0), "");
        _diamondCut(new Facet[](0), regulatoryCompliance_, initRegulatory_);
        _diamondCut(new Facet[](0), kycCompliance_, initKYC_);
    }

    /// @inheritdoc IAssetF
    function diamondCut(
        Facet[] memory modules_
    ) public virtual override onlyRole(_diamondCutRole()) {
        diamondCut(modules_, address(0), "");
    }

    /// @inheritdoc IAssetF
    function diamondCut(
        Facet[] memory modules_,
        address initModule_,
        bytes memory initData_
    ) public virtual override onlyRole(_diamondCutRole()) {
        _diamondCut(modules_, initModule_, initData_);
    }

    function _mintRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }

    function _burnRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }

    function _forcedTransferRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }

    function _recoveryRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }

    function _diamondCutRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }
}
