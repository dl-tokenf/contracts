// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISBT} from "@solarity/solidity-lib/interfaces/tokens/ISBT.sol";

import {Context} from "../../core/Globals.sol";
import {AbstractKYCModule} from "../AbstractKYCModule.sol";

/**
 * @notice `RarimoModule` is an example of a possible KYC module implementation,
 * within which the user's SBT token is checked.
 */
abstract contract RarimoModule is AbstractKYCModule {
    bytes32 public constant HAS_SOUL_SENDER_TOPIC = keccak256("HAS_SOUL_SENDER");
    bytes32 public constant HAS_SOUL_RECIPIENT_TOPIC = keccak256("HAS_SOUL_RECIPIENT");
    bytes32 public constant HAS_SOUL_OPERATOR_TOPIC = keccak256("HAS_SOUL_OPERATOR");

    address private _sbt;

    function __RarimoModule_init(address sbt_) internal onlyInitializing {
        _sbt = sbt_;
    }

    function getSBT() public view virtual returns (address) {
        return _sbt;
    }

    function _handlerer() internal virtual override {
        _setHandler(HAS_SOUL_SENDER_TOPIC, _handleHasSoulSenderTopic);
        _setHandler(HAS_SOUL_RECIPIENT_TOPIC, _handleHasSoulRecipientTopic);
        _setHandler(HAS_SOUL_OPERATOR_TOPIC, _handleHasSoulOperatorTopic);
    }

    function _handleHasSoulSenderTopic(Context memory ctx_) internal view virtual returns (bool) {
        return ISBT(_sbt).balanceOf(ctx_.from) > 0;
    }

    function _handleHasSoulRecipientTopic(
        Context memory ctx_
    ) internal view virtual returns (bool) {
        return ISBT(_sbt).balanceOf(ctx_.to) > 0;
    }

    function _handleHasSoulOperatorTopic(
        Context memory ctx_
    ) internal view virtual returns (bool) {
        return ISBT(_sbt).balanceOf(ctx_.operator) > 0;
    }

    uint256[49] private _gap;
}
