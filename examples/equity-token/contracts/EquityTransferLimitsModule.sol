// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "@tokenf/contracts/core/TokenF.sol";
import {TransferLimitsModule} from "@tokenf/contracts/modules/regulatory/TransferLimitsModule.sol";

contract EquityTransferLimitsModule is TransferLimitsModule {
    function __EquityTransferLimitsModule_init(address tokenF_) external initializer {
        __AbstractModule_init(tokenF_);
        __TransferLimitsModule_init(1 ether, MAX_TRANSFER_LIMIT);
    }

    function getClaimTopicKey(bytes4 selector_) external view returns (bytes32) {
        TokenF.Context memory ctx_;
        ctx_.selector = selector_;

        return _getClaimTopicKey(ctx_);
    }
}
