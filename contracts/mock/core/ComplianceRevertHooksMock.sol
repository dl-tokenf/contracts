// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../../core/TokenF.sol";

contract ComplianceRevertHooksMock {
    function transferred(TokenF.Context memory) external pure {
        revert("ComplianceRevertHooksMock: revert");
    }

    function isKYCed(TokenF.Context memory) external pure returns (bool) {
        revert("ComplianceRevertHooksMock: revert");
    }

    function canTransfer(TokenF.Context memory) external pure returns (bool) {
        revert("ComplianceRevertHooksMock: revert");
    }
}
