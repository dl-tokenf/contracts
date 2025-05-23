// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "../interfaces/IAssetF.sol";

import {AbstractModule} from "./AbstractModule.sol";

/**
 * @notice The `AbstractKYCModule` contract is the standard base implementation for KYC modules.
 */
abstract contract AbstractKYCModule is AbstractModule {
    function __AbstractKYCModule_init() internal onlyInitializing {}

    function isKYCed(IAssetF.Context memory ctx_) public view virtual returns (bool) {
        return _handle(ctx_);
    }
}
