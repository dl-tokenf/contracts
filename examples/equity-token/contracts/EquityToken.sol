// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "@tokenf/contracts/core/TokenF.sol";

contract EquityToken is TokenF {
    function __EquityToken_init(
        address regulatoryCompliance_,
        address kycCompliance_,
        bytes memory initRegulatory_,
        bytes memory initKYC_
    )
        external
        initializer(DIAMOND_ERC20_STORAGE_SLOT)
        initializer(DIAMOND_ACCESS_CONTROL_STORAGE_SLOT)
        initializer(AGENT_ACCESS_CONTROL_STORAGE_SLOT)
        initializer(TOKEN_F_STORAGE_SLOT)
    {
        __DiamondAccessControl_init();
        __DiamondERC20_init("Equity Token", "ET");
        __AgentAccessControl_init();
        __TokenF_init(regulatoryCompliance_, kycCompliance_, initRegulatory_, initKYC_);
    }
}
