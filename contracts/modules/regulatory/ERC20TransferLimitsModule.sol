// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "../../interfaces/IAssetF.sol";

import {AbstractRegulatoryModule} from "../AbstractRegulatoryModule.sol";

/**
 * @notice `ERC20TransferLimitsModule` is an example of a possible implementation of a regulatory module,
 * which adds rules for minimum and maximum amount for transfers.
 */
abstract contract ERC20TransferLimitsModule is AbstractRegulatoryModule {
    bytes32 public constant MIN_TRANSFER_LIMIT_TOPIC = keccak256("MIN_TRANSFER_LIMIT");
    bytes32 public constant MAX_TRANSFER_LIMIT_TOPIC = keccak256("MAX_TRANSFER_LIMIT");

    uint256 public constant MAX_TRANSFER_LIMIT = type(uint256).max;

    // keccak256("tokenf.standard.transfer.limits.module.storage")
    bytes32 private constant TRANSFER_LIMIT_MODULE_STORAGE =
        0x82b479944bd9cd9d0ec7327a8e71ac032b254d7dc2d3bf169455e0079540dee7;

    struct TransferLimitsModuleStorage {
        uint256 minTransferLimit;
        uint256 maxTransferLimit;
    }

    function __ERC20TransferLimitsModule_init(
        uint256 minTransferValue_,
        uint256 maxTransferValue_
    ) internal onlyInitializing {
        TransferLimitsModuleStorage storage $ = _getTransferLimitsModuleStorage();

        $.minTransferLimit = minTransferValue_;
        $.maxTransferLimit = maxTransferValue_;
    }

    function setMinTransferLimit(
        uint256 minTransferLimit_
    ) public virtual onlyRole(_moduleRole()) {
        TransferLimitsModuleStorage storage $ = _getTransferLimitsModuleStorage();

        $.minTransferLimit = minTransferLimit_;
    }

    function setMaxTransferLimit(
        uint256 maxTransferLimit_
    ) public virtual onlyRole(_moduleRole()) {
        TransferLimitsModuleStorage storage $ = _getTransferLimitsModuleStorage();

        $.maxTransferLimit = maxTransferLimit_;
    }

    function _handlerer() internal virtual override {
        _setHandler(MIN_TRANSFER_LIMIT_TOPIC, _handleMinTransferLimitTopic);
        _setHandler(MAX_TRANSFER_LIMIT_TOPIC, _handleMaxTransferLimitTopic);
    }

    function getTransferLimits() public view virtual returns (uint256, uint256) {
        TransferLimitsModuleStorage storage $ = _getTransferLimitsModuleStorage();

        return ($.minTransferLimit, $.maxTransferLimit);
    }

    function _handleMinTransferLimitTopic(
        IAssetF.Context memory ctx_
    ) internal view virtual returns (bool) {
        TransferLimitsModuleStorage storage $ = _getTransferLimitsModuleStorage();

        return ctx_.amount >= $.minTransferLimit;
    }

    function _handleMaxTransferLimitTopic(
        IAssetF.Context memory ctx_
    ) internal view virtual returns (bool) {
        TransferLimitsModuleStorage storage $ = _getTransferLimitsModuleStorage();

        return ctx_.amount <= $.maxTransferLimit;
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getTransferLimitsModuleStorage()
        private
        pure
        returns (TransferLimitsModuleStorage storage $)
    {
        assembly {
            $.slot := TRANSFER_LIMIT_MODULE_STORAGE
        }
    }
}
