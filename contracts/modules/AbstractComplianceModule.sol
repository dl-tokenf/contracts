// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IAgentAccessControl} from "../interfaces/IAgentAccessControl.sol";

import {TokenF} from "../core/TokenF.sol";

abstract contract AbstractComplianceModule is Initializable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    modifier onlyRole(bytes32 role_) {
        _onlyRole(role_);
        _;
    }

    address private _tokenF;

    mapping(bytes32 => EnumerableSet.Bytes32Set) private _claimTopics;
    mapping(bytes32 => function(TokenF.Context memory) internal view returns (bool))
        private _handlers;

    function __AbstractComplianceModule_init(address tokenF_) internal onlyInitializing {
        _tokenF = tokenF_;

        _router();
    }

    function _router() internal virtual;

    function _getClaimTopicKey(TokenF.Context memory ctx_) internal view virtual returns (bytes32);

    function addClaimTopics(
        bytes32 claimTopicKey_,
        bytes32[] memory claimTopics_
    ) public virtual onlyRole(_complianceModuleRole()) {
        _addClaimTopics(claimTopicKey_, claimTopics_);
    }

    function removeClaimTopics(
        bytes32 claimTopicKey_,
        bytes32[] memory claimTopics_
    ) public virtual onlyRole(_complianceModuleRole()) {
        _removeClaimTopics(claimTopicKey_, claimTopics_);
    }

    function getClaimTopics(
        bytes32 claimTopicsKey_
    ) public view virtual returns (bytes32[] memory) {
        return _claimTopics[claimTopicsKey_].values();
    }

    function getTokenF() public view virtual returns (address) {
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

    function _setHandler(
        bytes32 claimTopic_,
        function(TokenF.Context memory) internal view returns (bool) handler_
    ) internal virtual {
        _handlers[claimTopic_] = handler_;
    }

    function _hook(TokenF.Context calldata ctx_) internal view virtual returns (bool) {
        TokenF.Context[] memory ctxs_ = _getExtContexts(ctx_);

        for (uint256 i = 0; i < ctxs_.length; ++i) {
            bytes32 claimTopicKey_ = _getClaimTopicKey(ctxs_[i]);
            bytes32[] memory claimTopics_ = getClaimTopics(claimTopicKey_);

            for (uint256 j = 0; j < claimTopics_.length; ++j) {
                if (!_getHandler(claimTopics_[j])(ctxs_[i])) {
                    return false;
                }
            }
        }

        return true;
    }

    function _getHandler(
        bytes32 claimTopic_
    )
        internal
        view
        virtual
        returns (function(TokenF.Context memory) internal view returns (bool))
    {
        return _handlers[claimTopic_];
    }

    function _getExtContexts(
        TokenF.Context calldata ctx_
    ) internal view virtual returns (TokenF.Context[] memory) {
        TokenF.Context[] memory ctxs_ = new TokenF.Context[](1);
        ctxs_[0] = ctx_;

        return ctxs_;
    }

    function _complianceModuleRole() internal view virtual returns (bytes32) {
        return IAgentAccessControl(_tokenF).AGENT_ROLE();
    }

    function _onlyRole(bytes32 role_) internal view virtual {
        IAgentAccessControl(_tokenF).checkRole(role_, msg.sender);
    }

    uint256[47] private _gap;
}
