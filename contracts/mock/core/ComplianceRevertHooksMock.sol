// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../../core/TokenF.sol";

contract ComplianceRevertHooksMock {
    error ComplianceHooksMockRevert();

    function transferred(TokenF.Context memory) external pure {
        revert ComplianceHooksMockRevert();
    }

    function isKYCed(TokenF.Context memory) external pure returns (bool) {
        revert ComplianceHooksMockRevert();
    }

    function canTransfer(TokenF.Context memory) external pure returns (bool) {
        revert ComplianceHooksMockRevert();
    }
}
