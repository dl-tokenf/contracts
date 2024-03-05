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

        if (
            _isCheckableAddress(tokenF_.TRANSFER_SENDER(), from_) &&
            !_isKYCed(from_, getClaimTopics(selector_, tokenF_.TRANSFER_SENDER(), ""))
        ) {
            return false;
        }

        if (
            _isCheckableAddress(tokenF_.TRANSFER_RECIPIENT(), to_) &&
            !_isKYCed(to_, getClaimTopics(selector_, tokenF_.TRANSFER_RECIPIENT(), ""))
        ) {
            return false;
        }

        if (
            _isCheckableAddress(tokenF_.TRANSFER_OPERATOR(), operator_) &&
            !_isKYCed(operator_, getClaimTopics(selector_, tokenF_.TRANSFER_OPERATOR(), ""))
        ) {
            return false;
        }

        return true;
    }

    function getSBT() public view virtual returns (address) {
        return _sbt;
    }

    function _isCheckableAddress(
        uint8 transferRole_,
        address user_
    ) internal view virtual returns (bool) {
        return user_ != address(0);
    }

    function _isKYCed(address account_, bytes32[] memory) internal view virtual returns (bool) {
        return ISBT(_sbt).balanceOf(account_) > 0;
    }

    uint256[49] private _gap;
}
