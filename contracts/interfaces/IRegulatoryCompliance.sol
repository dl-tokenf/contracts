// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "../core/Globals.sol";
import {IRegulatoryComplianceView} from "./IRegulatoryComplianceView.sol";

/**
 * @notice `RegulatoryCompliance` contract is used to manage Regulatory Compliance modules.
 * It manages the storage, addition of new and deletion of existing Regulatory Compliance modules.
 *
 * It also implements the `canTransfer` and `transferred` hooks, which in turn are called by the `TokenF` or `NFTF` contracts.
 *
 * All actions for module management can only be done by users who have a special role.
 * In the basic version of `TokenF` and `NFTF` this role is the Agent role.
 *
 * It is possible to override the role that is required to configure the module list.
 *
 * Also this contract is used as a facet in the `TokenF` and `NFTF` contracts.
 */
interface IRegulatoryCompliance is IRegulatoryComplianceView {
    error SenderIsNotThisContract(address sender);

    /**
     * @notice Function is required to add new regulatory modules to the `RegulatoryCompliance` contract.
     *
     * If you try to add a module that already exists in the list of regulatory modules,
     * the transaction will fail with an error - `SetHelper: element already exists`.
     *
     * This function in the basic `TokenF` and `NFTF` implementations can only be called by users who have the Agent role.
     *
     * An internal function `_regulatoryComplianceRole` is used to retrieve the role that is used during validation,
     * which can be overridden if you want to use a role other than Agent.
     *
     * @param rModules_ The array with regulatory modules to add
     */
    function addRegulatoryModules(address[] memory rModules_) external;

    /**
     * @notice Function is required to delete existing regulatory modules from the list in the `RegulatoryCompliance` contract.
     *
     * If you try to delete a module that is not in the list of regulatory modules,
     * the transaction will crash with an error - `SetHelper: no such element`.
     *
     * This function in the basic `TokenF` and `NFTF` implementations can only be called by users who have the Agent role.
     *
     * An internal function `_regulatoryComplianceRole` is used to retrieve the role that is used during validation,
     * which can be overridden if you want to use a role other than Agent
     *
     * @param rModules_ The array with regulatory modules to remove
     */
    function removeRegulatoryModules(address[] memory rModules_) external;

    /**
     * @notice Function that is needed to write some information to modules after the main transaction logic has been executed.
     *
     * This hook can be used, for example, to restrict token transfers within one day.
     * That is, it is an addition to modules that need to save an additional state to check a rule.
     *
     * @param ctx_ The context of transaction
     */
    function transferred(Context memory ctx_) external;

    /**
     * @notice Function that is used to verify that all necessary regulatory rules that have been added to `RegulatoryCompliance` have been met.
     *
     * The entire transaction context is passed for validation, giving modules full information for further checks.
     *
     * @param ctx_ The context of transaction
     * @return true if the passed context satisfies the rules in all installed regulatory modules.
     */
    function canTransfer(Context memory ctx_) external view returns (bool);
}
