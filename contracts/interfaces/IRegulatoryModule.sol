// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRegulatoryModule {
    function transferred(
        bytes4 selector_,
        address from_,
        address to_,
        uint256 amount_,
        address operator_,
        bytes memory data_
    ) external;

    function canTransfer(
        bytes4 selector_,
        address from_,
        address to_,
        uint256 amount_,
        address operator_,
        bytes memory data_
    ) external view returns (bool);

    function getTokenF() external view returns (address);
}
