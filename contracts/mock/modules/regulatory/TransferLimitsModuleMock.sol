// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../../../core/TokenF.sol";
import {TransferLimitsModule} from "../../../modules/regulatory/TransferLimitsModule.sol";

contract TransferLimitsModuleMock is TransferLimitsModule {
    function __TransferLimitsModuleMock_init(
        address tokenF_,
        uint256 minTransferValue_,
        uint256 maxTransferValue_
    ) external initializer {
        __AbstractModule_init(tokenF_);
        __AbstractRegulatoryModule_init();
        __TransferLimitsModule_init(minTransferValue_, maxTransferValue_);
    }

    function getClaimTopicKey(bytes4 selector_) external view returns (bytes32) {
        TokenF.Context memory ctx_;
        ctx_.selector = selector_;

        return _getClaimTopicKey(ctx_);
    }
}
