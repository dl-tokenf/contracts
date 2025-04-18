// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Diamond} from "@solarity/solidity-lib/diamond/Diamond.sol";

/**
 * @notice `IAssetF` is a shared interface for both TokenF and NFTF contracts
 */
interface IAssetF {
    /**
     * @notice The transaction context
     * @param selector The selector of called function
     * @param from The address from which token is sent
     * @param to The address to which token is sent
     * @param amount The amount of tokens to send (for TokenF contract)
     * @param tokenId The id of token to send (for NFTF contract)
     * @param operator The address of the operator
     * @param data The transaction data
     */
    struct Context {
        bytes4 selector;
        address from;
        address to;
        uint256 amount;
        uint256 tokenId;
        address operator;
        bytes data;
    }

    error CannotTransfer();
    error CanTransferReverted();
    error NotKYCed();
    error IsKYCedReverted();
    error TransferredReverted();

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
     * In the base version of `AssetF` this role is the Agent role.
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
     * @notice The function is required to manage the list of facets in a `AssetF` contracts.
     * It can be used to add, delete and update existing facets.
     *
     * This function can only be called by users who have a special role.
     * In the basic version of `AssetF` this role is the Agent role.
     *
     * To change the role used for access validation,
     * you must override `_diamondCutRole` according to the requirements of your business task
     *
     * @param modules_ The array of modules to update
     */
    function diamondCut(Diamond.Facet[] memory modules_) external;

    /**
     * @notice This function overloads another `diamondCut` function of the contract,
     * allowing you to pass an additional calldata to call the necessary methods using `delegateCall` on the facet address.
     * Often this calldata is needed to call various init functions.
     *
     * This function can only be called by users who have a special role.
     * In the basic version of `AssetF` this role is the Agent role.
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
