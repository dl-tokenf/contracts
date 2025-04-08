// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAssetF} from "../../interfaces/IAssetF.sol";

contract ComplianceRevertHooksMock {
    error ComplianceHooksMockRevert();

    function transferred(IAssetF.Context memory) external pure {
        revert ComplianceHooksMockRevert();
    }

    function isKYCed(IAssetF.Context memory) external pure returns (bool) {
        revert ComplianceHooksMockRevert();
    }

    function canTransfer(IAssetF.Context memory) external pure returns (bool) {
        revert ComplianceHooksMockRevert();
    }
}
