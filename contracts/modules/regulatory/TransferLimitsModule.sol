// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Context} from "../../core/Globals.sol";

import {AbstractRegulatoryModule} from "../AbstractRegulatoryModule.sol";

/**
 * @notice `TransferLimitsModule` is an example of a possible implementation of a regulatory module,
 * which adds rules for minimum and maximum amount for transfers.
 */
abstract contract TransferLimitsModule is AbstractRegulatoryModule {
    bytes32 public constant MIN_TRANSFER_LIMIT_TOPIC = keccak256("MIN_TRANSFER_LIMIT");
    bytes32 public constant MAX_TRANSFER_LIMIT_TOPIC = keccak256("MAX_TRANSFER_LIMIT");

    uint256 public constant MAX_TRANSFER_LIMIT = type(uint256).max;

    uint256 private _minTransferLimit;
    uint256 private _maxTransferLimit;

    function __TransferLimitsModule_init(
        uint256 minTransferValue_,
        uint256 maxTransferValue_
    ) internal onlyInitializing {
        _minTransferLimit = minTransferValue_;
        _maxTransferLimit = maxTransferValue_;
    }

    function setMinTransferLimit(
        uint256 minTransferLimit_
    ) public virtual onlyRole(_moduleRole()) {
        _minTransferLimit = minTransferLimit_;
    }

    function setMaxTransferLimit(
        uint256 maxTransferLimit_
    ) public virtual onlyRole(_moduleRole()) {
        _maxTransferLimit = maxTransferLimit_;
    }

    function _handlerer() internal virtual override {
        _setHandler(MIN_TRANSFER_LIMIT_TOPIC, _handleMinTransferLimitTopic);
        _setHandler(MAX_TRANSFER_LIMIT_TOPIC, _handleMaxTransferLimitTopic);
    }

    function getTransferLimits()
        public
        view
        virtual
        returns (uint256 minTransferLimit_, uint256 maxTransferLimit_)
    {
        return (_minTransferLimit, _maxTransferLimit);
    }

    function _handleMinTransferLimitTopic(
        Context memory ctx_
    ) internal view virtual returns (bool) {
        return ctx_.amount >= _minTransferLimit;
    }

    function _handleMaxTransferLimitTopic(
        Context memory ctx_
    ) internal view virtual returns (bool) {
        return ctx_.amount <= _maxTransferLimit;
    }

    uint256[48] private _gap;
}
