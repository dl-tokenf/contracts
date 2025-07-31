// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ASBT} from "@solarity/solidity-lib/tokens/ASBT.sol";

contract EquitySBT is ASBT, OwnableUpgradeable {
    function __EquitySBT_init() external initializer {
        __ASBT_init("EquitySBT", "EquitySBT");
        __Ownable_init(msg.sender);
    }

    function mint(address to_, uint256 tokenId_) external virtual onlyOwner {
        _mint(to_, tokenId_);
    }

    function burn(uint256 tokenId_) external virtual onlyOwner {
        _burn(tokenId_);
    }
}
