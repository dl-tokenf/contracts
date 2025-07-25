// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ISBT} from "@solarity/solidity-lib/interfaces/tokens/ISBT.sol";

import {IAssetF} from "../../interfaces/IAssetF.sol";
import {AbstractKYCModule} from "../AbstractKYCModule.sol";

/**
 * @notice `SimpleKYCModule` is an example of a possible KYC module implementation,
 * within which the user's SBT token is checked.
 */
abstract contract SimpleKYCModule is AbstractKYCModule {
    bytes32 public constant HAS_SOUL_SENDER_TOPIC = keccak256("HAS_SOUL_SENDER");
    bytes32 public constant HAS_SOUL_RECIPIENT_TOPIC = keccak256("HAS_SOUL_RECIPIENT");
    bytes32 public constant HAS_SOUL_OPERATOR_TOPIC = keccak256("HAS_SOUL_OPERATOR");

    // keccak256("tokenf.standard.simple.kyc.module.storage")
    bytes32 private constant SIMPLE_KYC_MODULE_STORAGE =
        0x38deaaaa98559b0911f428b8b3b9bbf960af9ad1ba4f2251fc09aa6872c543ae;

    struct SimpleKYCModuleStorage {
        address sbt;
    }

    function __SimpleKYCModule_init(address sbt_) internal onlyInitializing {
        SimpleKYCModuleStorage storage $ = _getSimpleKYCModuleStorage();

        $.sbt = sbt_;
    }

    function getSBT() public view virtual returns (address) {
        SimpleKYCModuleStorage storage $ = _getSimpleKYCModuleStorage();

        return $.sbt;
    }

    function _handlerer() internal virtual override {
        _setHandler(HAS_SOUL_SENDER_TOPIC, _handleHasSoulSenderTopic);
        _setHandler(HAS_SOUL_RECIPIENT_TOPIC, _handleHasSoulRecipientTopic);
        _setHandler(HAS_SOUL_OPERATOR_TOPIC, _handleHasSoulOperatorTopic);
    }

    function _handleHasSoulSenderTopic(
        IAssetF.Context memory ctx_
    ) internal view virtual returns (bool) {
        return _hasSBT(ctx_.from);
    }

    function _handleHasSoulRecipientTopic(
        IAssetF.Context memory ctx_
    ) internal view virtual returns (bool) {
        return _hasSBT(ctx_.to);
    }

    function _handleHasSoulOperatorTopic(
        IAssetF.Context memory ctx_
    ) internal view virtual returns (bool) {
        return _hasSBT(ctx_.operator);
    }

    function _hasSBT(address userAddr_) internal view returns (bool) {
        return ISBT(_getSimpleKYCModuleStorage().sbt).balanceOf(userAddr_) > 0;
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getSimpleKYCModuleStorage() private pure returns (SimpleKYCModuleStorage storage $) {
        assembly {
            $.slot := SIMPLE_KYC_MODULE_STORAGE
        }
    }
}
