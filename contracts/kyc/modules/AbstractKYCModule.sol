// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {IKYCModule} from "../../interfaces/IKYCModule.sol";

abstract contract AbstractKYCModule is IKYCModule, Initializable {
    address private _tokenF;

    function __AbstractKYCModule_init(address tokenF_) internal onlyInitializing {
        _tokenF = tokenF_;
    }

    function getTokenF() public view virtual override returns (address) {
        return _tokenF;
    }

    uint256[49] private _gap;
}
