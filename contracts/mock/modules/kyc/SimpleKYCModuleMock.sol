// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "../../../interfaces/IAssetF.sol";
import {SimpleKYCModule} from "../../../modules/kyc/SimpleKYCModule.sol";

contract SimpleKYCModuleMock is SimpleKYCModule {
    function __SimpleKYCModuleMock_init(address assetF_, address sbt_) external initializer {
        __AbstractModule_init(assetF_);
        __AbstractKYCModule_init();
        __SimpleKYCModule_init(sbt_);
    }

    function __SimpleKYCModuleDirect_init() external {
        __SimpleKYCModule_init(address(0));
    }

    function getContextKey(bytes4 selector_) external view returns (bytes32) {
        IAssetF.Context memory ctx_;
        ctx_.selector = selector_;

        return _getContextKey(ctx_);
    }
}
