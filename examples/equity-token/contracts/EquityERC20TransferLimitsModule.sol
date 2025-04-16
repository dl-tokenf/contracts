// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "@tokenf/contracts/interfaces/IAssetF.sol";
import {ERC20TransferLimitsModule} from "@tokenf/contracts/modules/regulatory/ERC20TransferLimitsModule.sol";

contract EquityERC20TransferLimitsModule is ERC20TransferLimitsModule {
    function __EquityERC20TransferLimitsModule_init(address tokenF_) external initializer {
        __AbstractModule_init(tokenF_);
        __ERC20TransferLimitsModule_init(1 ether, MAX_TRANSFER_LIMIT);
    }

    function getContextKey(bytes4 selector_) external view returns (bytes32) {
        IAssetF.Context memory ctx_;
        ctx_.selector = selector_;

        return _getContextKey(ctx_);
    }
}
