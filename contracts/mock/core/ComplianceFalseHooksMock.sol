// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAssetF} from "../../interfaces/IAssetF.sol";

contract ComplianceFalseHooksMock {
    function isKYCed(IAssetF.Context memory) external pure returns (bool) {
        return false;
    }

    function canTransfer(IAssetF.Context memory) external pure returns (bool) {
        return false;
    }
}
