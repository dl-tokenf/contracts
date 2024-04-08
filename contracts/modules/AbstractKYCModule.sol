// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../core/TokenF.sol";

import {AbstractModule} from "./AbstractModule.sol";

/**
 * @notice The `AbstractKYCModule` contract is the standard base implementation for KYC modules.
 */
abstract contract AbstractKYCModule is AbstractModule {
    function __AbstractKYCModule_init() internal onlyInitializing {}

    function isKYCed(TokenF.Context memory ctx_) public view virtual returns (bool) {
        return _handle(ctx_);
    }

    uint256[50] private _gap;
}
