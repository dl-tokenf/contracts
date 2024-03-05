// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SBT} from "@solarity/solidity-lib/tokens/SBT.sol";

contract RarimoSBT is SBT {
    function __RarimoSBT_init() external initializer {
        __SBT_init("RarimoSBT", "RarimoSBT");
    }
}
