// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "../../../core/Globals.sol";
import {RarimoModule} from "../../../modules/kyc/RarimoModule.sol";

contract RarimoModuleMock is RarimoModule {
    function __RarimoModuleMock_init(address assetF_, address sbt_) external initializer {
        __AbstractModule_init(assetF_);
        __AbstractKYCModule_init();
        __RarimoModule_init(sbt_);
    }

    function __RarimoModuleDirect_init() external {
        __RarimoModule_init(address(0));
    }

    function getContextKey(bytes4 selector_) external view returns (bytes32) {
        Context memory ctx_;
        ctx_.selector = selector_;

        return _getContextKey(ctx_);
    }
}
