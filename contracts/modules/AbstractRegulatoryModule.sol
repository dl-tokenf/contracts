// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "../core/Globals.sol";

import {AbstractModule} from "./AbstractModule.sol";

/**
 * @notice `AbstractRegulatoryModule` contract is the standard base implementation for regulatory modules.
 */
abstract contract AbstractRegulatoryModule is AbstractModule {
    modifier onlyAssetF() {
        _onlyAssetF();
        _;
    }

    error SenderNotAssetF(address sender);

    function __AbstractRegulatoryModule_init() internal onlyInitializing {}

    function transferred(Context memory ctx_) public virtual onlyAssetF {}

    function canTransfer(Context memory ctx_) public view virtual returns (bool) {
        return _handle(ctx_);
    }

    function _onlyAssetF() internal view {
        require(msg.sender == getAssetF(), SenderNotAssetF(msg.sender));
    }

    uint256[50] private _gap;
}
