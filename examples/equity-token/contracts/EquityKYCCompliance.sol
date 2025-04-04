// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {KYCCompliance} from "@tokenf/contracts/core/KYCCompliance.sol";

contract EquityKYCCompliance is KYCCompliance {
    function __EquityKYCCompliance_init() external {
        __KYCCompliance_init();
    }
}
