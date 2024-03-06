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

    mapping(bytes32 => EnumerableSet.Bytes32Set) private _claimTopics;

    function __AbstractKYCModule_init(address tokenF_) internal onlyInitializing {
        _tokenF = tokenF_;
    }

    function addClaimTopics(
        bytes32 claimTopicKey_,
        bytes32[] memory claimTopics_
    ) public virtual onlyRole(_KYCModuleRole()) {
        _addClaimTopics(claimTopicKey_, claimTopics_);
    }

    function removeClaimTopics(
        bytes32 claimTopicKey_,
        bytes32[] memory claimTopics_
    ) public virtual onlyRole(_KYCModuleRole()) {
        _removeClaimTopics(claimTopicKey_, claimTopics_);
    }

    function getClaimTopics(
        bytes32 claimTopicsKey_
    ) public view virtual returns (bytes32[] memory) {
        return _claimTopics[claimTopicsKey_].values();
    }

    function getTokenF() public view virtual override returns (address) {
        return _tokenF;
    }

    function _addClaimTopics(
        bytes32 claimTopicKey_,
        bytes32[] memory claimTopics_
    ) internal virtual {
        EnumerableSet.Bytes32Set storage _claimTopicList = _claimTopics[claimTopicKey_];

        for (uint256 i = 0; i < claimTopics_.length; ++i) {
            require(_claimTopicList.add(claimTopics_[i]), "KYCModule: claim topic exists");
        }
    }

    function _removeClaimTopics(
        bytes32 claimTopicKey_,
        bytes32[] memory claimTopics_
    ) internal virtual {
        EnumerableSet.Bytes32Set storage _claimTopicList = _claimTopics[claimTopicKey_];

        for (uint256 i = 0; i < claimTopics_.length; ++i) {
            require(
                _claimTopicList.remove(claimTopics_[i]),
                "KYCModule: claim topic doesn't exist"
            );
        }
    }

    function _getClaimTopicsKey(
        bytes4 selector_,
        uint8 transferRole_,
        bytes memory
    ) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked(selector_, transferRole_));
    }

    function _KYCModuleRole() internal view virtual returns (bytes32) {
        return IAgentAccessControl(_tokenF).AGENT_ROLE();
    }

    uint256[48] private _gap;
}
