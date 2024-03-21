// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../core/TokenF.sol";

interface IRegulatoryCompliance {
    function addRegulatoryModules(address[] memory rModules_) external;

    function removeRegulatoryModules(address[] memory rModules_) external;

    function transferred(TokenF.Context calldata ctx_) external;

    function canTransfer(TokenF.Context calldata ctx_) external view returns (bool);
}
