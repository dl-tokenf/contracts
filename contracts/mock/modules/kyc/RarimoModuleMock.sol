// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../../../core/TokenF.sol";
import {RarimoModule} from "../../../modules/kyc/RarimoModule.sol";

contract RarimoModuleMock is RarimoModule {
    function __RarimoModuleMock_init(address tokenF_, address sbt_) external initializer {
        __AbstractModule_init(tokenF_);
        __AbstractKYCModule_init();
        __RarimoModule_init(sbt_);
    }

    function getClaimTopicKey(bytes4 selector_) external view returns (bytes32) {
        TokenF.Context memory ctx_;
        ctx_.selector = selector_;

        return _getClaimTopicKey(ctx_);
    }

    function _getExtContexts(
        TokenF.Context calldata ctx_
    ) internal view override returns (TokenF.Context[] memory) {
        TokenF.Context[] memory ctxs_ = new TokenF.Context[](1);
        ctxs_[0] = ctx_;

        return ctxs_;
    }

    function _getClaimTopicKey(
        TokenF.Context memory ctx_
    ) internal view override returns (bytes32) {
        return keccak256(abi.encodePacked(ctx_.selector));
    }
}
