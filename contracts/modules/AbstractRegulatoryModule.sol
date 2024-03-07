// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../core/TokenF.sol";

import {AbstractComplianceModule} from "./AbstractComplianceModule.sol";

abstract contract AbstractRegulatoryModule is AbstractComplianceModule {
    function __AbstractRegulatoryModule_init() internal onlyInitializing {}

    function transferred(TokenF.Context calldata ctx_) public virtual {}

    function canTransfer(TokenF.Context calldata ctx_) public view virtual returns (bool) {
        return _hook(ctx_);
    }

    function _getClaimTopicKey(
        TokenF.Context memory ctx_
    ) internal view virtual override returns (bytes32) {
        return keccak256(abi.encodePacked(ctx_.selector));
    }

    uint256[50] private _gap;
}
