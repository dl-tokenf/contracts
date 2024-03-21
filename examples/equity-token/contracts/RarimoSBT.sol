// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {SBT} from "@solarity/solidity-lib/tokens/SBT.sol";

contract RarimoSBT is SBT, OwnableUpgradeable {
    function __RarimoSBT_init() external initializer {
        __SBT_init("RarimoSBT", "RarimoSBT");
        __Ownable_init();
    }

    function mint(address to_, uint256 tokenId_) external virtual onlyOwner {
        _mint(to_, tokenId_);
    }

    function burn(uint256 tokenId_) external virtual onlyOwner {
        _burn(tokenId_);
    }
}
