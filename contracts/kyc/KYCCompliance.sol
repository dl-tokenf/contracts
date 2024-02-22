// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IKYCModule} from "../interfaces/IKYCModule.sol";
import {KYCComplianceStorage} from "./KYCComplianceStorage.sol";

abstract contract KYCCompliance is KYCComplianceStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier onlyThis() {
        require(msg.sender == address(this), "KYCCompliance: not this");
        _;
    }

    modifier onlyRole() {
        _;
    }

    function addKYCModules(address[] memory kycModules_) public virtual onlyRole {
        EnumerableSet.AddressSet storage _kycModules = _getKYCComplianceStorage().kycModules;

        for (uint256 i = 0; i < kycModules_.length; ++i) {
            require(_kycModules.add(kycModules_[i]), "KYCCompliance: modules exists");
        }
    }

    function removeKYCModules(address[] memory kycModules_) public virtual onlyRole {
        EnumerableSet.AddressSet storage _kycModules = _getKYCComplianceStorage().kycModules;

        for (uint256 i = 0; i < kycModules_.length; ++i) {
            require(_kycModules.remove(kycModules_[i]), "KYCCompliance: modules doesn't exist");
        }
    }

    function isKYCed(
        bytes4 selector_,
        address from_,
        address to_,
        uint256 amount_,
        address operator_
    ) public view virtual onlyThis returns (bool) {
        address[] memory regulatoryModules_ = getKYCModules();

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            if (
                !IKYCModule(regulatoryModules_[i]).isKYCed(
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
}
