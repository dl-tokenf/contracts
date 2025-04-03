// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "../core/Globals.sol";
import {IKYCComplianceView} from "./IKYCComplianceView.sol";

/**
 * @notice `KYCCompliance` contract is used to manage KYC Compliance modules.
 * It performs storage, addition of new KYC modules and deletion of existing KYC modules.
 *
 * It also implements the `isKYCed` hook, which in turn is called by the `TokenF` or `NFTF` contract.
 *
 * All actions for module management can only be done by users who have a special role.
 * In the basic version of `TokenF` and `NFTF` this role is the Agent role.
 *
 * It is possible to override the role that is required to configure the module list.
 *
 * Also this contract is used as a facet in the `TokenF` or `NFTF` contract.
 */
interface IKYCCompliance is IKYCComplianceView {
    /**
     * @notice Function is required to add new KYC modules to a `KYCCompliance` contract.
     *
     * If you try to add a module that already exists in the list of KYC modules,
     * the transaction will fail with an error - `SetHelper: element already exists`.
     *
     * This function in the basic `TokenF` and `NFTF` implementations can only be called by users who have Agent role.
     *
     * An internal function `_KYCComplianceRole` is used to retrieve the role that is used in the validation,
     * which can be overridden if you want to use a role other than Agent.
     *
     * @param kycModules_ The array of KYC modules to add
     */
    function addKYCModules(address[] memory kycModules_) external;

    /**
     * @notice Function is required to remove existing KYC modules from the list in the `KYCCompliance` contract.
     *
     * If you try to delete a module that is not in the list of KYC modules,
     * the transaction will fail with an error - `SetHelper: no such element`.
     *
     * This function in the basic `TokenF` or `NFTF` implementations can only be called by users who have the Agent role.
     *
     * An internal function `_KYCComplianceRole` is used to retrieve the role that is used in the validation,
     * which can be overridden if you want to use a role other than Agent.
     *
     * @param kycModules_ The array with KYC modules to remove
     */
    function removeKYCModules(address[] memory kycModules_) external;

    /**
     * @notice Function that is used to verify that all required KYC rules that have been added to `KYCCompliance` are met.
     *
     * The entire transaction context is passed to the checker, giving modules full information for further checks.
     *
     * @param ctx_ The context of the transaction
     * @return true if the passed context satisfies the checks on all modules
     */
    function isKYCed(Context memory ctx_) external view returns (bool);
}
