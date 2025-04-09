// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "../../../interfaces/IAssetF.sol";
import {TransferLimitsModule} from "../../../modules/regulatory/TransferLimitsModule.sol";

contract TransferLimitsModuleMock is TransferLimitsModule {
    function __TransferLimitsModuleMock_init(
        address assetF_,
        uint256 minTransferValue_,
        uint256 maxTransferValue_
    ) external initializer {
        __AbstractModule_init(assetF_);
        __AbstractRegulatoryModule_init();
        __TransferLimitsModule_init(minTransferValue_, maxTransferValue_);
    }

    function __TransferLimitsDirect_init() external {
        __TransferLimitsModule_init(0, 0);
    }

    function __AbstractModuleDirect_init() external {
        __AbstractModule_init(address(0));
    }

    function __AbstractRegulatoryModuleDirect_init() external {
        __AbstractRegulatoryModule_init();
    }

    function getContextKey(bytes4 selector_) external view returns (bytes32) {
        IAssetF.Context memory ctx_;
        ctx_.selector = selector_;

        return _getContextKey(ctx_);
    }
}
