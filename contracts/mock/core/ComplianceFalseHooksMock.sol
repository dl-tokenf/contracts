// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "../../core/Globals.sol";

contract ComplianceFalseHooksMock {
    function isKYCed(Context memory) external pure returns (bool) {
        return false;
    }

    function canTransfer(Context memory) external pure returns (bool) {
        return false;
    }
}
