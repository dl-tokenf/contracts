// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegulatoryCompliance} from "@tokenf/contracts/regulatory/RegulatoryCompliance.sol";

contract EquityRegulatoryCompliance is RegulatoryCompliance {
    function __EquityRegulatoryCompliance_init()
        external
        initializer(REGULATORY_COMPLIANCE_STORAGE_SLOT)
    {
        __RegulatoryCompliance_init();
    }
}
