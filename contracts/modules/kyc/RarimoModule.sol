// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ISBT} from "@solarity/solidity-lib/interfaces/tokens/ISBT.sol";

import {TokenF} from "../../core/TokenF.sol";
import {AbstractKYCModule} from "../AbstractKYCModule.sol";

abstract contract RarimoModule is AbstractKYCModule {
    using Address for address;

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

    function _router() internal virtual override {
        _setHandler(HAS_SOUL_SENDER_TOPIC, _handleHasSoulSenderTopic);
        _setHandler(HAS_SOUL_RECIPIENT_TOPIC, _handleHasSoulRecipientTopic);
        _setHandler(HAS_SOUL_OPERATOR_TOPIC, _handleHasSoulOperatorTopic);
    }

    function _handleHasSoulSenderTopic(
        TokenF.Context memory ctx_
    ) internal view virtual returns (bool) {
        return ISBT(_sbt).balanceOf(ctx_.from) > 0;
    }

    function _handleHasSoulRecipientTopic(
        TokenF.Context memory ctx_
    ) internal view virtual returns (bool) {
        return ISBT(_sbt).balanceOf(ctx_.to) > 0;
    }

    function _handleHasSoulOperatorTopic(
        TokenF.Context memory ctx_
    ) internal view virtual returns (bool) {
        if (ctx_.operator.isContract()) {
            /// @dev If the operator is a contract, it has no identity.
            /// In this case, it's enough that it has a certain role in `AccessControl` to initiate the transfer.
            return true;
        }

        return ISBT(_sbt).balanceOf(ctx_.operator) > 0;
    }

    uint256[49] private _gap;
}
