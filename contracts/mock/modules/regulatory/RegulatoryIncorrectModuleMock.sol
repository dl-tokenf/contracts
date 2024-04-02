// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../../../core/TokenF.sol";
import {AbstractRegulatoryModule} from "../../../modules/AbstractRegulatoryModule.sol";
import {IRegulatoryCompliance} from "../../../interfaces/IRegulatoryCompliance.sol";

contract RegulatoryIncorrectModuleMock is AbstractRegulatoryModule {
    function _handlerer() internal override {}

    function transferred(TokenF.Context calldata ctx_) public override {}

    function canTransfer(TokenF.Context calldata) public pure override returns (bool) {
        return false;
    }
}
