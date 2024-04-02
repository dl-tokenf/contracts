// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Diamond} from "@solarity/solidity-lib/diamond/Diamond.sol";

/**
 * @notice The `TokenF` contract
 *
 * The `TokenF` is a Diamond-based ERC20 token implementation enabling the storage of all core contracts under the same Diamond proxy.
 *
 * The `TokenF` provides flexibility for implementing eligibility checks through the integration of compliance modules without
 * affecting the standard ERC20 behaviour.
 *
 * Transfer methods forward the entire transfer context to compliance modules, ensuring adherence to specific requirements,
 * such as regulatory standards or KYC protocols.
 *
 * `TokenF` is also inherited from `AgentAccessControl`, which is built on Solarity's `DiamondAccessControl`.
 * This inheritance allows to realise a rather flexible system of roles for controlling privileged functions in the whole system.
 */
interface ITokenF is IERC20Metadata {
    struct Context {
        bytes4 selector;
        address from;
        address to;
        uint256 amount;
        address operator;
        bytes data;
    }

    /**
     * @notice Function to create new `TokenF` contract tokens.
     *
     * The `isKYCed` hook from the `KYCCompliance` contract is used inside the function to check KYC.
     * The `canTransfer` and `transferred` hooks are used to check the established regulatory rules
     * from `RegulatoryCompliance` contract
     *
     * This function can only be called by users who have a special role.
     * In the base version of `TokenF` this role is the Agent role.
     *
     * To change the role used for access validation,
     * you need to override `_mintRole` according to the requirements of your business task.
     *
     * @param account_ The address to which tokens should be minted
     * @param amount_ The amount of tokens to be minted
     * @return true in all cases if not reverted
     */
    function mint(address account_, uint256 amount_) external returns (bool);

    /**
     * @notice Function to burn existing `TokenF` contract tokens.
     *
     * The `isKYCed` hook from the `KYCCompliance` contract is used within the function to check KYC.
     * The `canTransfer` and `transferred` hooks are used to check the established regulatory rules
     * from the `RegulatoryCompliance` contract.
     *
     * This function can only be called by users who have a special role.
     * In the base version of `TokenF` this role is the Agent role.
     *
     * To change the role used for access verification,
     * you must override `_burnRole` according to the requirements of your business task.
     *
     * @param account_ The address of the user whose balance you want to burn tokens from
     * @param amount_ The amount of tokens to be burned
     * @return true in all cases if not reverted
     */
    function burn(address account_, uint256 amount_) external returns (bool);

    /**
     * @notice Function for forced transfering from one address to another.
     *
     * This logic may be needed for smart contracts that will operate with `TokenF` tokens.
     * It will be convenient because users will not need to call `approve` function additionally.
     *
     * The `isKYCed` hook from the `KYCCompliance` contract is used inside the function to check KYC.
     * The `canTransfer` and `transferred` hooks are used to check the established regulatory rules
     * from `RegulatoryCompliance` contract.
     *
     * This function can only be called by users who have a special role.
     * In the base version of `TokenF` this role is the Agent role.
     *
     * To change the role used for access verification,
     * you must override `_forcedTransferRole` according to the requirements of your business task.
     *
     * @param from_ The user address where the tokens will be transferred from
     * @param to_ The user address to whom tokens will be transferred
     * @param amount_ The amount of tokens to be transferred
     * @return true in all cases if not reverted
     */
    function forcedTransfer(address from_, address to_, uint256 amount_) external returns (bool);

    /**
     * @notice Function for balance transfer from one account to another.
     *
     * This function can be useful if the user has lost the private key to his account.
     * In this case, the system can check the user's KYC and transfer the user's funds to a new account.
     *
     * The `isKYCed` hook from the `KYCCompliance` contract is used inside the function to check the KYC.
     * The `canTransfer` and `transferred` hooks are used to check the established regulatory rules
     * from `RegulatoryCompliance` contract.
     *
     * This function can only be called by users who have a special role.
     * In the base version of `TokenF` this role is the Agent role.
     *
     * To change the role used for access verification,
     * you need to redefine `_recoveryRole` according to the requirements of your business task.
     *
     * @param oldAccount_ The address of the user's old account
     * @param newAccount_ The address of the new user account to which the tokens will be migrated
     * @return true in all cases if not reverted
     */
    function recovery(address oldAccount_, address newAccount_) external returns (bool);

    /**
     * @notice The function is required to manage the list of facets in a `TokenF` contract.
     * It can be used to add, delete and update existing facets.
     *
     * This function can only be called by users who have a special role.
     * In the basic version of `TokenF` this role is the Agent role.
     *
     * To change the role used for access validation,
     * you must override `_diamondCutRole` according to the requirements of your business task
     *
     * @param modules_ The array of modules to update
     */
    function diamondCut(Diamond.Facet[] memory modules_) external;

    /**
     * @notice This function overloads another `diamondCut` function `TokenF` of the contract,
     * allowing you to pass an additional calldata to call the necessary methods using `delegateCall` on the facet address.
     * Often this calldata is needed to call various init functions.
     *
     * This function can only be called by users who have a special role.
     * In the basic version of `TokenF` this role is the Agent role.
     *
     * To change the role used for access validation,
     * you must override `_diamondCutRole` according to the requirements of your business task.
     *
     * @param modules_ The array of modules to update
     * @param initModule_ The address of the module to execute the passed caldata
     * @param initData_ The calldata to be executed
     */
    function diamondCut(
        Diamond.Facet[] memory modules_,
        address initModule_,
        bytes memory initData_
    ) external;
}
