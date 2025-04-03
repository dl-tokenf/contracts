// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "@tokenf/contracts/core/Globals.sol";
import {TransferLimitsModule} from "@tokenf/contracts/modules/regulatory/TransferLimitsModule.sol";

contract EquityTransferLimitsModule is TransferLimitsModule {
    function __EquityTransferLimitsModule_init(address assetF_) external initializer {
        __AbstractModule_init(assetF_);
        __TransferLimitsModule_init(1 ether, MAX_TRANSFER_LIMIT);
    }

    function getContextKey(bytes4 selector_) external view returns (bytes32) {
        Context memory ctx_;
        ctx_.selector = selector_;

        return _getContextKey(ctx_);
    }
}
