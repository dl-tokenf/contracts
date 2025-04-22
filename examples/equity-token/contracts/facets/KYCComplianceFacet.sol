// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {KYCCompliance} from "@tokenf/contracts/core/KYCCompliance.sol";

contract KYCComplianceFacet is KYCCompliance {
    function __KYCComplianceFacet_init() external onlyInitializing {
        __KYCCompliance_init();
    }
}
