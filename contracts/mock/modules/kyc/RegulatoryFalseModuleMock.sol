// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../../../core/TokenF.sol";
import {AbstractRegulatoryModule} from "../../../modules/AbstractRegulatoryModule.sol";

contract RegulatoryFalseModuleMock is AbstractRegulatoryModule {
    function _handlerer() internal override {}

    function transferred(TokenF.Context calldata) public override {}

    function canTransfer(TokenF.Context calldata) public view override returns (bool) {
        return false;
    }
}
