// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TransferLimitsModule} from "@tokenf/contracts/modules/regulatory/TransferLimitsModule.sol";

contract EquityTransferLimitsModule is TransferLimitsModule {
    function __EquityTransferLimitsModule_init(address tokenF_) external initializer {
        __AbstractComplianceModule_init(tokenF_);
        __TransferLimitsModule_init(1 ether, MAX_TRANSFER_LIMIT);
    }
}
