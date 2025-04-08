// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegulatoryCompliance} from "@tokenf/contracts/core/RegulatoryCompliance.sol";

contract EquityRegulatoryCompliance is RegulatoryCompliance {
    function __EquityRegulatoryCompliance_init() external onlyInitializing {
        __RegulatoryCompliance_init();
    }
}
