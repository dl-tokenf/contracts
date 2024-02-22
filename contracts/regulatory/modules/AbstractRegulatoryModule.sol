// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {IRegulatoryModule} from "../../interfaces/IRegulatoryModule.sol";

abstract contract AbstractRegulatoryModule is IRegulatoryModule, Initializable {
    address private _tokenF;

    function __AbstractRegulatoryModule_init(address tokenF_) internal onlyInitializing {
        _tokenF = tokenF_;
    }

    function getTokenF() public view virtual override returns (address) {
        return _tokenF;
    }

    uint256[49] private _gap;
}
