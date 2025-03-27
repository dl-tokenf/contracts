// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../core/TokenF.sol";

import {AbstractModule} from "./AbstractModule.sol";

/**
 * @notice `AbstractRegulatoryModule` contract is the standard base implementation for regulatory modules.
 */
abstract contract AbstractRegulatoryModule is AbstractModule {
    modifier onlyTokenF() {
        _onlyTokenF();
        _;
    }

    error SenderNotTokenF(address sender);

    function __AbstractRegulatoryModule_init() internal onlyInitializing {}

    function transferred(TokenF.Context memory ctx_) public virtual onlyTokenF {}

    function canTransfer(TokenF.Context memory ctx_) public view virtual returns (bool) {
        return _handle(ctx_);
    }

    function _onlyTokenF() internal view {
        require(msg.sender == getTokenF(), SenderNotTokenF(msg.sender));
    }

    uint256[50] private _gap;
}
