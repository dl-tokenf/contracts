// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
