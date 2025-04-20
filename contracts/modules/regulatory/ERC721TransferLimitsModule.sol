// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "../../interfaces/IAssetF.sol";

import {AbstractRegulatoryModule} from "../AbstractRegulatoryModule.sol";

/**
 * @notice `ERC721TransferLimitsModule` is an example of a possible implementation of a regulatory module,
 * which adds rules for maximum amount of transfers for a sender.
 */
abstract contract ERC721TransferLimitsModule is AbstractRegulatoryModule {
    bytes32 public constant MAX_TRANSFERS_PER_PERIOD_TOPIC = keccak256("MAX_TRANSFERS_PER_PERIOD");

    // keccak256("tokenf.standard.erc721.transfer.limits.module.storage")
    bytes32 private constant ERC721_TRANSFER_LIMIT_MODULE_STORAGE =
        0xb697c813dd02e38de7d797a75bdca0cac7d121e95943023d79ae3ec48e1360ad;

    struct ERC721TransferLimitsModuleStorage {
        uint256 maxTransfersPerPeriod;
        uint256 timePeriod;
        mapping(address sender => TransferData transferData) transferData;
    }

    struct TransferData {
        uint256 lastTransferTimestamp;
        uint256 amountOfTransfers;
    }

    function __ERC721TransferLimitsModule_init(
        uint256 maxTransfersPerPeriod_,
        uint256 timePeriod_
    ) internal onlyInitializing {
        ERC721TransferLimitsModuleStorage storage $ = _getERC721TransferLimitsModuleStorage();

        $.maxTransfersPerPeriod = maxTransfersPerPeriod_;
        $.timePeriod = timePeriod_;
    }

    function transferred(IAssetF.Context memory ctx_) public virtual override onlyAssetF {
        ERC721TransferLimitsModuleStorage storage $ = _getERC721TransferLimitsModuleStorage();

        if (_isNewPeriod(ctx_.from)) {
            $.transferData[ctx_.from].amountOfTransfers = 0;
        }

        $.transferData[ctx_.from].amountOfTransfers++;
        $.transferData[ctx_.from].lastTransferTimestamp = block.timestamp;

        super.transferred(ctx_);
    }

    function setMaxTransfersPerPeriod(
        uint256 maxTransfersPerPeriod_
    ) public virtual onlyRole(_moduleRole()) {
        ERC721TransferLimitsModuleStorage storage $ = _getERC721TransferLimitsModuleStorage();

        $.maxTransfersPerPeriod = maxTransfersPerPeriod_;
    }

    function setTimePeriod(uint256 timePeriod_) public virtual onlyRole(_moduleRole()) {
        ERC721TransferLimitsModuleStorage storage $ = _getERC721TransferLimitsModuleStorage();

        $.timePeriod = timePeriod_;
    }

    function getMaxTransfersPerPeriod() public view virtual returns (uint256) {
        ERC721TransferLimitsModuleStorage storage $ = _getERC721TransferLimitsModuleStorage();

        return $.maxTransfersPerPeriod;
    }

    function getTimePeriod() public view virtual returns (uint256) {
        ERC721TransferLimitsModuleStorage storage $ = _getERC721TransferLimitsModuleStorage();

        return $.timePeriod;
    }

    function _handlerer() internal virtual override {
        _setHandler(MAX_TRANSFERS_PER_PERIOD_TOPIC, _handleMaxTransferLimitPerPeriodTopic);
    }

    function _handleMaxTransferLimitPerPeriodTopic(
        IAssetF.Context memory ctx_
    ) internal view virtual returns (bool) {
        ERC721TransferLimitsModuleStorage storage $ = _getERC721TransferLimitsModuleStorage();

        return
            _isNewPeriod(ctx_.from) ||
            $.transferData[ctx_.from].amountOfTransfers <= $.maxTransfersPerPeriod;
    }

    function _isNewPeriod(address user_) public view virtual returns (bool) {
        ERC721TransferLimitsModuleStorage storage $ = _getERC721TransferLimitsModuleStorage();

        return
            block.timestamp / $.timePeriod >
            $.transferData[user_].lastTransferTimestamp / $.timePeriod;
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getERC721TransferLimitsModuleStorage()
        private
        pure
        returns (ERC721TransferLimitsModuleStorage storage $)
    {
        assembly {
            $.slot := ERC721_TRANSFER_LIMIT_MODULE_STORAGE
        }
    }
}
