// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../../core/TokenF.sol";

contract ComplianceFalseHooksMock {
    function isKYCed(TokenF.Context calldata) external returns (bool) {
        return false;
    }

    function canTransfer(TokenF.Context calldata) external returns (bool) {
        return false;
    }
}
