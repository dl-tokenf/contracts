// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RarimoModule} from "@tokenf/contracts/kyc/modules/RarimoModule.sol";

contract EquityRarimoModule is RarimoModule {
    function __EquityRarimoModule_init(address tokenF_, address sbt_) external initializer {
        __AbstractKYCModule_init(tokenF_);
        __RarimoModule_init(sbt_);
    }
}
