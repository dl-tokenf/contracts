// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISBT} from "@solarity/solidity-lib/interfaces/tokens/ISBT.sol";

import {AbstractKYCModule} from "./AbstractKYCModule.sol";

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
        address,
        bytes memory
    ) public view virtual override returns (bool) {
        if (isBypassedSelector(selector_)) {
            return true;
        }

        return _isKYCed(to_, getClaimTopics());
    }

    function getSBT() public view virtual returns (address) {
        return _sbt;
    }

    function _isKYCed(address account_, bytes32[] memory) internal view virtual returns (bool) {
        return ISBT(_sbt).balanceOf(account_) > 0;
    }

    uint256[49] private _gap;
}
