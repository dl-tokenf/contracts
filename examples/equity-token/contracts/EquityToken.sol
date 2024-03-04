// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@tokenf/contracts/TokenF.sol";

contract EquityToken is TokenF {
    function __EquityToken_init()
        external
        initializer(DIAMOND_ERC20_STORAGE_SLOT)
        initializer(DIAMOND_ACCESS_CONTROL_STORAGE_SLOT)
    {
        __DiamondAccessControl_init();
        __DiamondERC20_init("Equity Token", "ET");
    }
}
