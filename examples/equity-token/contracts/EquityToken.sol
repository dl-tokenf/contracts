// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "@tokenf/contracts/TokenF.sol";

contract EquityToken is TokenF {
    function __EquityToken_init(
        address regulatoryCompliance_,
        address kycCompliance_
    )
        external
        initializer(DIAMOND_ERC20_STORAGE_SLOT)
        initializer(DIAMOND_ACCESS_CONTROL_STORAGE_SLOT)
        initializer(TOKEN_F_STORAGE_SLOT)
    {
        __DiamondAccessControl_init();
        __DiamondERC20_init("Equity Token", "ET");
        __TokenF_init(regulatoryCompliance_, kycCompliance_);

        grantRole(AGENT_ROLE, msg.sender);
    }
}
