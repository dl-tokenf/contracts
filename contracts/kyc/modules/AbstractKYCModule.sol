// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IAgentAccessControl} from "../../interfaces/IAgentAccessControl.sol";
import {IKYCModule} from "../../interfaces/IKYCModule.sol";

abstract contract AbstractKYCModule is IKYCModule, Initializable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct ClaimTopicsParams {
        bytes4 selector;
        uint8 transferRole;
        bytes32[] claimTopics;
    }

    modifier onlyRole(bytes32 role_) {
        IAgentAccessControl(_tokenF).checkRole(role_, msg.sender);
        _;
    }

    address private _tokenF;

    mapping(bytes4 => mapping(uint8 => EnumerableSet.Bytes32Set)) private _claimTopics;

    function __AbstractKYCModule_init(address tokenF_) internal onlyInitializing {
        _tokenF = tokenF_;
    }

    function addClaimTopics(
        ClaimTopicsParams[] memory requests_
    ) public virtual onlyRole(_KYCModuleRole()) {
        _addClaimTopics(requests_);
    }

    function removeClaimTopics(
        ClaimTopicsParams[] memory requests_
    ) public virtual onlyRole(_KYCModuleRole()) {
        _removeClaimTopics(requests_);
    }

    function getClaimTopics(
        bytes4 selector_,
        uint8 transferRole_,
        bytes memory
    ) public view virtual returns (bytes32[] memory) {
        return _claimTopics[selector_][transferRole_].values();
    }

    function getTokenF() public view virtual override returns (address) {
        return _tokenF;
    }

    function _addClaimTopics(ClaimTopicsParams[] memory requests_) internal virtual {
        for (uint256 i = 0; i < requests_.length; ++i) {
            ClaimTopicsParams memory request_ = requests_[i];

            for (uint256 j = 0; j < request_.claimTopics.length; ++j) {
                require(
                    _claimTopics[request_.selector][request_.transferRole].add(
                        request_.claimTopics[j]
                    ),
                    "KYCModule: claim topic exists"
                );
            }
        }
    }

    function _removeClaimTopics(ClaimTopicsParams[] memory requests_) internal virtual {
        for (uint256 i = 0; i < requests_.length; ++i) {
            ClaimTopicsParams memory request_ = requests_[i];

            for (uint256 j = 0; j < request_.claimTopics.length; ++j) {
                require(
                    _claimTopics[request_.selector][request_.transferRole].remove(
                        request_.claimTopics[j]
                    ),
                    "KYCModule: claim topic doesn't exist"
                );
            }
        }
    }

    function _KYCModuleRole() internal view virtual returns (bytes32) {
        return IAgentAccessControl(_tokenF).getAgentRole();
    }

    uint256[48] private _gap;
}
