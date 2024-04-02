// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../../core/TokenF.sol";

contract ComplianceRevertHooksMock {
    function transferred(TokenF.Context calldata) external {
        revert("ComplianceRevertHooksMock: revert");
    }

    function isKYCed(TokenF.Context calldata) external view returns (bool) {
        revert("ComplianceRevertHooksMock: revert");
    }

    function canTransfer(TokenF.Context calldata) external view returns (bool) {
        revert("ComplianceRevertHooksMock: revert");
    }
}
