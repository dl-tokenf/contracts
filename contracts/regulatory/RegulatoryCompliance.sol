// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IRegulatoryModule} from "../interfaces/IRegulatoryModule.sol";
import {AgentAccessControl} from "../access/AgentAccessControl.sol";
import {RegulatoryComplianceStorage} from "./RegulatoryComplianceStorage.sol";

abstract contract RegulatoryCompliance is RegulatoryComplianceStorage, AgentAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier onlyThis() {
        require(msg.sender == address(this), "RCompliance: not this");
        _;
    }

    function addRegulatoryModules(
        address[] memory rModules_
    ) public virtual onlyRole(_manageRegulatoryModulesRole()) {
        EnumerableSet.AddressSet storage _regulatoryModules = _getRegulatoryComplianceStorage()
            .regulatoryModules;

        for (uint256 i = 0; i < rModules_.length; ++i) {
            require(_regulatoryModules.add(rModules_[i]), "RCompliance: modules exists");
        }
    }

    function removeRegulatoryModules(
        address[] memory rModules_
    ) public virtual onlyRole(_manageRegulatoryModulesRole()) {
        EnumerableSet.AddressSet storage _regulatoryModules = _getRegulatoryComplianceStorage()
            .regulatoryModules;

        for (uint256 i = 0; i < rModules_.length; ++i) {
            require(_regulatoryModules.remove(rModules_[i]), "RCompliance: modules doesn't exist");
        }
    }

    function transferred(
        bytes4 selector_,
        address from_,
        address to_,
        uint256 amount_,
        address operator_
    ) public virtual onlyThis {
        address[] memory regulatoryModules_ = getRegulatoryModules();

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            IRegulatoryModule(regulatoryModules_[i]).transferred(
                selector_,
                from_,
                to_,
                amount_,
                operator_
            );
        }
    }

    function canTransfer(
        bytes4 selector_,
        address from_,
        address to_,
        uint256 amount_,
        address operator_
    ) public view virtual returns (bool) {
        address[] memory regulatoryModules_ = getRegulatoryModules();

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            if (
                !IRegulatoryModule(regulatoryModules_[i]).canTransfer(
                    selector_,
                    from_,
                    to_,
                    amount_,
                    operator_
                )
            ) {
                return false;
            }
        }

        return true;
    }

    function _manageRegulatoryModulesRole() internal view virtual returns (bytes32) {
        return getAgentRole();
    }
}
