// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "@tokenf/contracts/interfaces/IAssetF.sol";
import {SimpleKYCModule} from "@tokenf/contracts/modules/kyc/SimpleKYCModule.sol";

contract EquityKYCModule is SimpleKYCModule {
    function __EquityKYCModule_init(address assetF_, address sbt_) external initializer {
        __AbstractModule_init(assetF_);
        __SimpleKYCModule_init(sbt_);
    }

    function getContextKeyBySelector(bytes4 selector_) external view returns (bytes32) {
        IAssetF.Context memory ctx_;
        ctx_.selector = selector_;

        return getContextKey(ctx_);
    }
}
