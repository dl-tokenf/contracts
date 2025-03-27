// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SetHelper} from "@solarity/solidity-lib/libs/arrays/SetHelper.sol";

import {IRegulatoryCompliance} from "../interfaces/IRegulatoryCompliance.sol";

import {TokenF} from "./TokenF.sol";
import {AgentAccessControl} from "./AgentAccessControl.sol";
import {RegulatoryComplianceStorage} from "./storages/RegulatoryComplianceStorage.sol";

import {AbstractRegulatoryModule} from "../modules/AbstractRegulatoryModule.sol";

/**
 * @notice The RegulatoryCompliance contract
 *
 * The RegulatoryCompliance is a core contract that serves as a repository for regulatory modules.
 * It tracks every transfer made within the TokenF contract and disseminates its context to registered regulatory modules.
 */
abstract contract RegulatoryCompliance is
    IRegulatoryCompliance,
    RegulatoryComplianceStorage,
    AgentAccessControl
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SetHelper for EnumerableSet.AddressSet;

    modifier onlyThisContract() {
        require(msg.sender == address(this), SenderIsNotThisContract(msg.sender));
        _;
    }

    function __RegulatoryCompliance_init() internal onlyInitializing {}

    /// @inheritdoc IRegulatoryCompliance
    function addRegulatoryModules(
        address[] memory rModules_
    ) public virtual onlyRole(_regulatoryComplianceRole()) {
        _addRegulatoryModules(rModules_);
    }

    /// @inheritdoc IRegulatoryCompliance
    function removeRegulatoryModules(
        address[] memory rModules_
    ) public virtual onlyRole(_regulatoryComplianceRole()) {
        _removeRegulatoryModules(rModules_);
    }

    /// @inheritdoc IRegulatoryCompliance
    function transferred(TokenF.Context memory ctx_) public virtual onlyThisContract {
        address[] memory regulatoryModules_ = getRegulatoryModules();

        for (uint256 i = 0; i < regulatoryModules_.length; ++i) {
            AbstractRegulatoryModule(regulatoryModules_[i]).transferred(ctx_);
        }
    }

    /// @inheritdoc IRegulatoryCompliance
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
        _getRegulatoryComplianceStorage().regulatoryModules.strictAdd(regulatoryModules_);
    }

    function _removeRegulatoryModules(address[] memory regulatoryModules_) internal virtual {
        _getRegulatoryComplianceStorage().regulatoryModules.strictRemove(regulatoryModules_);
    }

    function _regulatoryComplianceRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }
}
