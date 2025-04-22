// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "@tokenf/contracts/interfaces/IAssetF.sol";
import {RarimoModule} from "@tokenf/contracts/modules/kyc/RarimoModule.sol";

contract EquityRarimoModule is RarimoModule {
    function __EquityRarimoModule_init(address assetF_, address sbt_) external initializer {
        __AbstractModule_init(assetF_);
        __RarimoModule_init(sbt_);
    }

    function getContextKey(bytes4 selector_) external view returns (bytes32) {
        IAssetF.Context memory ctx_;
        ctx_.selector = selector_;

        return _getContextKey(ctx_);
    }
}
