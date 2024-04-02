// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../../../core/TokenF.sol";
import {AbstractKYCModule} from "../../../modules/AbstractKYCModule.sol";

contract KYCTrueModuleMock is AbstractKYCModule {
    function _handlerer() internal override {}

    function isKYCed(TokenF.Context calldata) public view override returns (bool) {
        return true;
    }
}
