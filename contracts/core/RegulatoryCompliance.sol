// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IRegulatoryCompliance} from "../interfaces/IRegulatoryCompliance.sol";

import {TokenF} from "./TokenF.sol";
import {AgentAccessControl} from "./AgentAccessControl.sol";
import {RegulatoryComplianceStorage} from "./storages/RegulatoryComplianceStorage.sol";

import {AbstractRegulatoryModule} from "../modules/AbstractRegulatoryModule.sol";

abstract contract RegulatoryCompliance is
    IRegulatoryCompliance,
    RegulatoryComplianceStorage,
    AgentAccessControl
{
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier onlyThis() {
        require(msg.sender == address(this), "RCompliance: not this");
        _;
    }

    function __RegulatoryCompliance_init()
        internal
        onlyInitializing(REGULATORY_COMPLIANCE_STORAGE_SLOT)
    {}

    function addRegulatoryModules(
        address[] memory rModules_
    ) public virtual onlyRole(_regulatoryComplianceRole()) {
        _addRegulatoryModules(rModules_);
    }

    function removeRegulatoryModules(
        address[] memory rModules_
    ) public virtual onlyRole(_regulatoryComplianceRole()) {
        _removeRegulatoryModules(rModules_);
    }

    function transferred(TokenF.Context memory ctx_) public virtual onlyThis {
        address[] memory regulatoryModules_ = getRegulatoryModules();

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            AbstractRegulatoryModule(regulatoryModules_[i]).transferred(ctx_);
        }
    }

    function canTransfer(TokenF.Context memory ctx_) public view virtual returns (bool) {
        address[] memory regulatoryModules_ = getRegulatoryModules();

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            if (!AbstractRegulatoryModule(regulatoryModules_[i]).canTransfer(ctx_)) {
                return false;
            }
        }

        return true;
    }

    function _addRegulatoryModules(address[] memory regulatoryModules_) internal virtual {
        EnumerableSet.AddressSet storage _regulatoryModules = _getRegulatoryComplianceStorage()
            .regulatoryModules;

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            require(_regulatoryModules.add(regulatoryModules_[i]), "RCompliance: module exists");
        }
    }

    function _removeRegulatoryModules(address[] memory regulatoryModules_) internal virtual {
        EnumerableSet.AddressSet storage _regulatoryModules = _getRegulatoryComplianceStorage()
            .regulatoryModules;

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            require(
                _regulatoryModules.remove(regulatoryModules_[i]),
                "RCompliance: module doesn't exist"
            );
        }
    }

    function _regulatoryComplianceRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }
}
