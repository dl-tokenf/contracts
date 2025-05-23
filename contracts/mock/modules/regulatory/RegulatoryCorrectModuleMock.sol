// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "../../../interfaces/IAssetF.sol";
import {AbstractRegulatoryModule} from "../../../modules/AbstractRegulatoryModule.sol";

contract RegulatoryCorrectModuleMock is AbstractRegulatoryModule {
    function __RegulatoryCorrectModuleMock_init(address assetF_) external initializer {
        __AbstractModule_init(assetF_);
        __AbstractRegulatoryModule_init();
    }

    function _handlerer() internal override {}

    function canTransfer(IAssetF.Context memory) public pure override returns (bool) {
        return true;
    }
}
