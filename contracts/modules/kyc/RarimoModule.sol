// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ISBT} from "@solarity/solidity-lib/interfaces/tokens/ISBT.sol";

import {IAssetF} from "../../interfaces/IAssetF.sol";
import {AbstractKYCModule} from "../AbstractKYCModule.sol";

/**
 * @notice `RarimoModule` is an example of a possible KYC module implementation,
 * within which the user's SBT token is checked.
 */
abstract contract RarimoModule is AbstractKYCModule {
    bytes32 public constant HAS_SOUL_SENDER_TOPIC = keccak256("HAS_SOUL_SENDER");
    bytes32 public constant HAS_SOUL_RECIPIENT_TOPIC = keccak256("HAS_SOUL_RECIPIENT");
    bytes32 public constant HAS_SOUL_OPERATOR_TOPIC = keccak256("HAS_SOUL_OPERATOR");

    // keccak256("tokenf.standard.rarimo.module.storage")
    bytes32 private constant RARIMO_MODULE_STORAGE =
        0x4daee3f1bcf471e40cb8bb42f6957ecf0fb0ccfdf6e24496c76bda599dbc8902;

    struct RarimoModuleStorage {
        address sbt;
    }

    function __RarimoModule_init(address sbt_) internal onlyInitializing {
        RarimoModuleStorage storage $ = _getRarimoModuleStorage();

        $.sbt = sbt_;
    }

    function getSBT() public view virtual returns (address) {
        RarimoModuleStorage storage $ = _getRarimoModuleStorage();

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
        RarimoModuleStorage storage $ = _getRarimoModuleStorage();

        return ISBT($.sbt).balanceOf(ctx_.from) > 0;
    }

    function _handleHasSoulRecipientTopic(
        IAssetF.Context memory ctx_
    ) internal view virtual returns (bool) {
        RarimoModuleStorage storage $ = _getRarimoModuleStorage();

        return ISBT($.sbt).balanceOf(ctx_.to) > 0;
    }

    function _handleHasSoulOperatorTopic(
        IAssetF.Context memory ctx_
    ) internal view virtual returns (bool) {
        RarimoModuleStorage storage $ = _getRarimoModuleStorage();

        return ISBT($.sbt).balanceOf(ctx_.operator) > 0;
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getRarimoModuleStorage() private pure returns (RarimoModuleStorage storage $) {
        assembly {
            $.slot := RARIMO_MODULE_STORAGE
        }
    }
}
