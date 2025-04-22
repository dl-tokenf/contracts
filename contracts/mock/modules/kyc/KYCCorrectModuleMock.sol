// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "../../../interfaces/IAssetF.sol";
import {AbstractKYCModule} from "../../../modules/AbstractKYCModule.sol";

contract KYCCorrectModuleMock is AbstractKYCModule {
    function _handlerer() internal override {}

    function isKYCed(IAssetF.Context memory) public pure override returns (bool) {
        return true;
    }
}
