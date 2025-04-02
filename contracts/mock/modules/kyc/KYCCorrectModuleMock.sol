// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "../../../core/Globals.sol";
import {AbstractKYCModule} from "../../../modules/AbstractKYCModule.sol";

contract KYCCorrectModuleMock is AbstractKYCModule {
    function _handlerer() internal override {}

    function isKYCed(Context memory) public pure override returns (bool) {
        return true;
    }
}
