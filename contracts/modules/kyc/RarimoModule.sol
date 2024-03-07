// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ISBT} from "@solarity/solidity-lib/interfaces/tokens/ISBT.sol";

import {TokenF} from "../../core/TokenF.sol";
import {AbstractKYCModule} from "../AbstractKYCModule.sol";

abstract contract RarimoModule is AbstractKYCModule {
    using Address for address;

    bytes32 public constant HAS_SOUL_TOPIC = keccak256("HAS_SOUL");

    address private _sbt;

    function __RarimoModule_init(address sbt_) internal onlyInitializing {
        _sbt = sbt_;
    }

    function getSBT() public view virtual returns (address) {
        return _sbt;
    }

    function _router() internal virtual override {
        _setHandler(HAS_SOUL_TOPIC, _handleHasSoulTopic);
    }

    function _handleHasSoulTopic(TokenF.Context memory ctx_) internal view virtual returns (bool) {
        TransferParty transferParty_ = abi.decode(ctx_.data, (TransferParty));

        if (transferParty_ == TransferParty.Sender) {
            return ISBT(_sbt).balanceOf(ctx_.from) > 0;
        }

        if (transferParty_ == TransferParty.Recipient) {
            return ISBT(_sbt).balanceOf(ctx_.to) > 0;
        }

        revert("RarimoModule: unexpected party");
    }

    uint256[49] private _gap;
}
