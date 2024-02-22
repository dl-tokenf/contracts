// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

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
        address,
        address to_,
        uint256,
        address
    ) public view virtual override returns (bool) {
        if (selector_ == TokenF.forcedTransfer.selector || selector_ == TokenF.burn.selector) {
            return true;
        }

        return _isKYCed(to_);
    }

    function getSBT() public view virtual returns (address) {
        return _sbt;
    }

    function _isKYCed(address account_) internal view virtual returns (bool) {
        return ISBT(_sbt).balanceOf(account_) > 0;
    }

    uint256[49] private _gap;
}
