// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "../../../interfaces/IAssetF.sol";
import {ERC721TransferLimitsModule} from "../../../modules/regulatory/ERC721TransferLimitsModule.sol";

contract ERC721TransferLimitsModuleMock is ERC721TransferLimitsModule {
    function __ERC721TransferLimitsModuleMock_init(
        address assetF_,
        uint256 maxTransfersPerPeriod_,
        uint256 timePeriod_
    ) external initializer {
        __AbstractModule_init(assetF_);
        __AbstractRegulatoryModule_init();
        __ERC721TransferLimitsModule_init(maxTransfersPerPeriod_, timePeriod_);
    }

    function __TransferLimitsDirect_init() external {
        __ERC721TransferLimitsModule_init(0, 0);
    }

    function __AbstractModuleDirect_init() external {
        __AbstractModule_init(address(0));
    }

    function __AbstractRegulatoryModuleDirect_init() external {
        __AbstractRegulatoryModule_init();
    }

    function getContextKeyBySelector(bytes4 selector_) external view returns (bytes32) {
        IAssetF.Context memory ctx_;
        ctx_.selector = selector_;

        return getContextKey(ctx_);
    }
}
