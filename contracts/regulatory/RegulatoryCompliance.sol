// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {RegulatoryComplianceStorage} from "./RegulatoryComplianceStorage.sol";
import {IRegulatoryModule} from "../interfaces/IRegulatoryModule.sol";

abstract contract RegulatoryCompliance is RegulatoryComplianceStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier onlyPermission() {
        _;
    }

    function addRegulatoryModules(address[] memory rModules_) public virtual onlyPermission {
        EnumerableSet.AddressSet storage _regulatoryModules = _getRegulatoryComplianceStorage()
            .regulatoryModules;

        for (uint256 i = 0; i < rModules_.length; ++i) {
            require(_regulatoryModules.add(rModules_[i]), "RCompliance: modules exists");
        }
    }

    function removeRegulatoryModules(address[] memory rModules_) public virtual onlyPermission {
        EnumerableSet.AddressSet storage _regulatoryModules = _getRegulatoryComplianceStorage()
            .regulatoryModules;

        for (uint256 i = 0; i < rModules_.length; ++i) {
            require(_regulatoryModules.remove(rModules_[i]), "RCompliance: modules doesn't exist");
        }
    }

    function _transferred(
        bytes4 selector_,
        address from_,
        address to_,
        uint256 amount_,
        address operator_
    ) internal virtual {
        address[] memory regulatoryModules_ = getRegulatoryModules();

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            regulatoryModules_[i].functionDelegateCall(
                abi.encodeCall(
                    IRegulatoryModule.transferred,
                    (selector_, from_, to_, amount_, operator_)
                )
            );
        }
    }

    function _canTransfer(
        bytes4 selector_,
        address from_,
        address to_,
        uint256 amount_,
        address operator_
    ) internal virtual {
        address[] memory regulatoryModules_ = getRegulatoryModules();

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            regulatoryModules_[i].functionDelegateCall(
                abi.encodeCall(
                    IRegulatoryModule.canTransfer,
                    (selector_, from_, to_, amount_, operator_)
                )
            );
        }
    }
}
