// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "@tokenf/contracts/core/TokenF.sol";

contract EquityToken is TokenF {
    function __EquityToken_init(
        address regulatoryCompliance_,
        address kycCompliance_,
        bytes memory initRegulatory_,
        bytes memory initKYC_
    ) external initializer {
        __AccessControl_init();
        __ERC20_init("Equity Token", "ET");
        __AgentAccessControl_init();
        __TokenF_init(regulatoryCompliance_, kycCompliance_, initRegulatory_, initKYC_);
    }
}
