// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

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
}
