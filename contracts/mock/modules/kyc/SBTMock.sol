// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ASBT} from "@solarity/solidity-lib/tokens/ASBT.sol";

contract SBTMock is ASBT {
    function __SBTMock_init() external initializer {
        __ASBT_init("MockSBT", "MockSBT");
    }

    function mint(address to_, uint256 tokenId_) external {
        _mint(to_, tokenId_);
    }

    function burn(uint256 tokenId_) external {
        _burn(tokenId_);
    }
}
