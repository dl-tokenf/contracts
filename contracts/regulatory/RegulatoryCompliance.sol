// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IRegulatoryCompliance} from "../interfaces/IRegulatoryCompliance.sol";
import {IRegulatoryModule} from "../interfaces/IRegulatoryModule.sol";
import {AgentAccessControl} from "../access/AgentAccessControl.sol";
import {RegulatoryComplianceStorage} from "./RegulatoryComplianceStorage.sol";

contract RegulatoryCompliance is
    IRegulatoryCompliance,
    RegulatoryComplianceStorage,
    AgentAccessControl
{
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier onlyThis() {
        require(msg.sender == address(this), "RCompliance: not this");
        _;
    }

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

    function transferred(
        bytes4 selector_,
        address from_,
        address to_,
        uint256 amount_,
        address operator_,
        bytes memory data_
    ) public virtual onlyThis {
        address[] memory regulatoryModules_ = getRegulatoryModules();

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            IRegulatoryModule(regulatoryModules_[i]).transferred(
                selector_,
                from_,
                to_,
                amount_,
                operator_,
                data_
            );
        }
    }

    function canTransfer(
        bytes4 selector_,
        address from_,
        address to_,
        uint256 amount_,
        address operator_,
        bytes memory data_
    ) public view virtual returns (bool) {
        address[] memory regulatoryModules_ = getRegulatoryModules();

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            if (
                !IRegulatoryModule(regulatoryModules_[i]).canTransfer(
                    selector_,
                    from_,
                    to_,
                    amount_,
                    operator_,
                    data_
                )
            ) {
                return false;
            }
        }

        return true;
    }

    function _addRegulatoryModules(address[] memory rModules_) internal virtual {
        EnumerableSet.AddressSet storage _regulatoryModules = _getRegulatoryComplianceStorage()
            .regulatoryModules;

        for (uint256 i = 0; i < rModules_.length; ++i) {
            require(_regulatoryModules.add(rModules_[i]), "RCompliance: module exists");
        }
    }

    function _removeRegulatoryModules(address[] memory rModules_) internal virtual {
        EnumerableSet.AddressSet storage _regulatoryModules = _getRegulatoryComplianceStorage()
            .regulatoryModules;

        for (uint256 i = 0; i < rModules_.length; ++i) {
            require(_regulatoryModules.remove(rModules_[i]), "RCompliance: module doesn't exist");
        }
    }

    function _regulatoryComplianceRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }
}
