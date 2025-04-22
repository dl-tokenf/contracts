// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "../interfaces/IAssetF.sol";

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

    function transferred(IAssetF.Context memory ctx_) public virtual onlyAssetF {}

    function canTransfer(IAssetF.Context memory ctx_) public view virtual returns (bool) {
        return _handle(ctx_);
    }

    function _onlyAssetF() internal view {
        require(msg.sender == getAssetF(), SenderNotAssetF(msg.sender));
    }
}
