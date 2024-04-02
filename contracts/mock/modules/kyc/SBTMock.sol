// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SBT} from "@solarity/solidity-lib/tokens/SBT.sol";

contract SBTMock is SBT {
    function __SBTMock_init() external initializer {
        __SBT_init("MockSBT", "MockSBT");
    }

    function mint(address to_, uint256 tokenId_) external {
        _mint(to_, tokenId_);
    }

    function burn(uint256 tokenId_) external {
        _burn(tokenId_);
    }
}
