// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "../../core/Globals.sol";

contract ComplianceRevertHooksMock {
    error ComplianceHooksMockRevert();

    function transferred(Context memory) external pure {
        revert ComplianceHooksMockRevert();
    }

    function isKYCed(Context memory) external pure returns (bool) {
        revert ComplianceHooksMockRevert();
    }

    function canTransfer(Context memory) external pure returns (bool) {
        revert ComplianceHooksMockRevert();
    }
}
