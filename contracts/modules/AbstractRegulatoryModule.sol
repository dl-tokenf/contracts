// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../core/TokenF.sol";

import {AbstractModule} from "./AbstractModule.sol";

/**
 * @notice `AbstractRegulatoryModule` contract is the standard base implementation for regulatory modules.
 *
 * In this implementation, the overridden function `_getClaimTopicKey` creates a claim topic key as follows - `keccak256(selector)`,
 * which allows the rules to be defined separately for each function.
 */
abstract contract AbstractRegulatoryModule is AbstractModule {
    function __AbstractRegulatoryModule_init() internal onlyInitializing {}

    function transferred(TokenF.Context calldata ctx_) public virtual {}

    function canTransfer(TokenF.Context calldata ctx_) public view virtual returns (bool) {
        return _handle(ctx_);
    }

    function _getClaimTopicKey(
        TokenF.Context memory ctx_
    ) internal view virtual override returns (bytes32) {
        return keccak256(abi.encodePacked(ctx_.selector));
    }

    uint256[50] private _gap;
}
