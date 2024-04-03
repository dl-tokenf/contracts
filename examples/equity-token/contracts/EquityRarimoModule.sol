// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "@tokenf/contracts/core/TokenF.sol";
import {RarimoModule} from "@tokenf/contracts/modules/kyc/RarimoModule.sol";

contract EquityRarimoModule is RarimoModule {
    function __EquityRarimoModule_init(address tokenF_, address sbt_) external initializer {
        __AbstractModule_init(tokenF_);
        __RarimoModule_init(sbt_);
    }

    function getClaimTopicKey(bytes4 selector_) external view returns (bytes32) {
        TokenF.Context memory ctx_;
        ctx_.selector = selector_;

        return _getClaimTopicKey(ctx_);
    }
}
