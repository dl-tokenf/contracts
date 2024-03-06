// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISBT} from "@solarity/solidity-lib/interfaces/tokens/ISBT.sol";

import {AbstractKYCModule} from "./AbstractKYCModule.sol";
import {TokenF} from "../../TokenF.sol";

abstract contract RarimoModule is AbstractKYCModule {
    address private _sbt;

    function __RarimoModule_init(address sbt_) internal onlyInitializing {
        _sbt = sbt_;
    }

    function isKYCed(
        bytes4 selector_,
        address from_,
        address to_,
        uint256,
        address operator_,
        bytes memory
    ) public view virtual override returns (bool) {
        TokenF tokenF_ = TokenF(payable(getTokenF()));

        return
            _checkTransferParty(selector_, tokenF_.TRANSFER_SENDER(), from_, "") &&
            _checkTransferParty(selector_, tokenF_.TRANSFER_RECIPIENT(), to_, "") &&
            _checkTransferParty(selector_, tokenF_.TRANSFER_OPERATOR(), operator_, "");
    }

    function getSBT() public view virtual returns (address) {
        return _sbt;
    }

    function _checkTransferParty(
        bytes4 selector_,
        uint8 transferRole_,
        address transferParty_,
        bytes memory data_
    ) internal view virtual returns (bool) {
        if (!_isCheckableAddress(transferRole_, transferParty_)) {
            return false;
        }

        bytes32 claimTopicsKey_ = _getClaimTopicsKey(selector_, transferRole_, data_);
        bytes32[] memory claimTopics_ = getClaimTopics(claimTopicsKey_);

        return _isKYCed(transferParty_, claimTopics_);
    }

    function _isCheckableAddress(uint8, address user_) internal view virtual returns (bool) {
        return user_ != address(0);
    }

    function _isKYCed(
        address transferParty_,
        bytes32[] memory
    ) internal view virtual returns (bool) {
        return ISBT(_sbt).balanceOf(transferParty_) > 0;
    }

    uint256[49] private _gap;
}
