// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../../../core/TokenF.sol";
import {AbstractRegulatoryModule} from "../../../modules/AbstractRegulatoryModule.sol";

contract RegulatoryCorrectModuleMock is AbstractRegulatoryModule {
    function __RegulatoryCorrectModuleMock_init(address tokenF_) external initializer {
        __AbstractModule_init(tokenF_);
        __AbstractRegulatoryModule_init();
    }

    function _handlerer() internal override {}

    function canTransfer(TokenF.Context memory) public pure override returns (bool) {
        return true;
    }
}
