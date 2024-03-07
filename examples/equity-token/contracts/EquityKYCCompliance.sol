// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {KYCCompliance} from "@tokenf/contracts/core/KYCCompliance.sol";

contract EquityKYCCompliance is KYCCompliance {
    function __EquityKYCCompliance_init() external initializer(KYC_COMPLIANCE_STORAGE_SLOT) {
        __KYCCompliance_init();
    }
}
