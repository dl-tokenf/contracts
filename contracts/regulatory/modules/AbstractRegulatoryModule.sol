// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {IAgentAccessControl} from "../../interfaces/IAgentAccessControl.sol";
import {IRegulatoryModule} from "../../interfaces/IRegulatoryModule.sol";

abstract contract AbstractRegulatoryModule is IRegulatoryModule, Initializable {
    modifier onlyRole(bytes32 role_) {
        IAgentAccessControl(_tokenF).checkRole(role_, msg.sender);
        _;
    }

    address private _tokenF;

    function __AbstractRegulatoryModule_init(address tokenF_) internal onlyInitializing {
        _tokenF = tokenF_;
    }

    function getTokenF() public view virtual override returns (address) {
        return _tokenF;
    }

    function _RModuleRole() internal view virtual returns (bytes32) {
        return IAgentAccessControl(_tokenF).getAgentRole();
    }

    uint256[49] private _gap;
}
