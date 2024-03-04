// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IAgentAccessControl} from "../../interfaces/IAgentAccessControl.sol";
import {IKYCModule} from "../../interfaces/IKYCModule.sol";

abstract contract AbstractKYCModule is IKYCModule, Initializable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    modifier onlyRole(bytes32 role_) {
        IAgentAccessControl(_tokenF).checkRole(role_, msg.sender);
        _;
    }

    address private _tokenF;

    mapping(bytes4 => bool) private _bypassedSelectors;
    EnumerableSet.Bytes32Set private _claimTopics;

    function __AbstractKYCModule_init(address tokenF_) internal onlyInitializing {
        _tokenF = tokenF_;
    }

    function addBypassedSelectors(
        bytes4[] memory selectors_
    ) public virtual onlyRole(_KYCModuleRole()) {
        _addBypassedSelectors(selectors_);
    }

    function removeBypassedSelectors(
        bytes4[] memory selectors_
    ) public virtual onlyRole(_KYCModuleRole()) {
        _removeBypassedSelectors(selectors_);
    }

    function addClaimTopics(
        bytes32[] memory claimTopics_
    ) public virtual onlyRole(_KYCModuleRole()) {
        _addClaimTopics(claimTopics_);
    }

    function removeClaimTopics(
        bytes32[] memory claimTopics_
    ) public virtual onlyRole(_KYCModuleRole()) {
        _removeClaimTopics(claimTopics_);
    }

    function isBypassedSelector(bytes4 selector_) public view virtual returns (bool) {
        return _bypassedSelectors[selector_];
    }

    function getClaimTopics() public view virtual returns (bytes32[] memory) {
        return _claimTopics.values();
    }

    function getTokenF() public view virtual override returns (address) {
        return _tokenF;
    }

    function _addBypassedSelectors(bytes4[] memory selectors_) internal virtual {
        for (uint256 i = 0; i < selectors_.length; ++i) {
            bytes4 selector_ = selectors_[i];

            require(!_bypassedSelectors[selector_], "KYCModule: selector is bypassed");

            _bypassedSelectors[selector_] = true;
        }
    }

    function _removeBypassedSelectors(bytes4[] memory selectors_) internal virtual {
        for (uint256 i = 0; i < selectors_.length; ++i) {
            bytes4 selector_ = selectors_[i];

            require(_bypassedSelectors[selector_], "KYCModule: selector is not bypassed");

            delete _bypassedSelectors[selector_];
        }
    }

    function _addClaimTopics(bytes32[] memory claimTopics_) internal virtual {
        for (uint256 i = 0; i < claimTopics_.length; ++i) {
            require(_claimTopics.add(claimTopics_[i]), "KYCModule: claim topic exists");
        }
    }

    function _removeClaimTopics(bytes32[] memory claimTopics_) internal virtual {
        for (uint256 i = 0; i < claimTopics_.length; ++i) {
            require(_claimTopics.remove(claimTopics_[i]), "KYCModule: claim topic doesn't exist");
        }
    }

    function _KYCModuleRole() internal view virtual returns (bytes32) {
        return IAgentAccessControl(_tokenF).getAgentRole();
    }

    uint256[47] private _gap;
}
