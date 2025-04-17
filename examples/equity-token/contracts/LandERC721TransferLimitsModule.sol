// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "@tokenf/contracts/contracts/interfaces/IAssetF.sol";
import {ERC721TransferLimitsModule} from "@tokenf/contracts/contracts/modules/regulatory/ERC721TransferLimitsModule.sol";

contract LandERC721TransferLimitsModule is ERC721TransferLimitsModule {
    uint256 public constant MAX_TRANSFERS_PER_PERIOD = 10;
    uint256 public constant TIME_PERIOD = 1 days;

    function __LandERC721TransferLimitsModule_init(address nftF_) external initializer {
        __AbstractModule_init(nftF_);
        __ERC721TransferLimitsModule_init(MAX_TRANSFERS_PER_PERIOD, TIME_PERIOD);
    }

    function getContextKey(bytes4 selector_) external view returns (bytes32) {
        IAssetF.Context memory ctx_;
        ctx_.selector = selector_;

        return _getContextKey(ctx_);
    }
}
