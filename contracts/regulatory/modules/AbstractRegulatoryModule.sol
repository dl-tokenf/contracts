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

    mapping(bytes4 => bool) private _bypassedSelectors;

    function __AbstractRegulatoryModule_init(address tokenF_) internal onlyInitializing {
        _tokenF = tokenF_;
    }

    function addBypassedSelectors(
        bytes4[] memory selectors_
    ) public virtual onlyRole(_RModuleRole()) {
        _addBypassedSelectors(selectors_);
    }

    function removeBypassedSelectors(
        bytes4[] memory selectors_
    ) public virtual onlyRole(_RModuleRole()) {
        _removeBypassedSelectors(selectors_);
    }

    function isBypassedSelector(bytes4 selector_) public view virtual returns (bool) {
        return _bypassedSelectors[selector_];
    }

    function getTokenF() public view virtual override returns (address) {
        return _tokenF;
    }

    function _addBypassedSelectors(bytes4[] memory selectors_) internal virtual {
        for (uint256 i = 0; i < selectors_.length; ++i) {
            bytes4 selector_ = selectors_[i];

            require(!_bypassedSelectors[selector_], "RModule: selector is bypassed");

            _bypassedSelectors[selector_] = true;
        }
    }

    function _removeBypassedSelectors(bytes4[] memory selectors_) internal virtual {
        for (uint256 i = 0; i < selectors_.length; ++i) {
            bytes4 selector_ = selectors_[i];

            require(_bypassedSelectors[selector_], "RModule: selector is not bypassed");

            delete _bypassedSelectors[selector_];
        }
    }

    function _RModuleRole() internal view virtual returns (bytes32) {
        return IAgentAccessControl(_tokenF).getAgentRole();
    }

    uint256[48] private _gap;
}
