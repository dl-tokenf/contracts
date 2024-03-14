// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SetHelper} from "@solarity/solidity-lib/libs/arrays/SetHelper.sol";

import {IAgentAccessControl} from "../interfaces/IAgentAccessControl.sol";

import {TokenF} from "../core/TokenF.sol";

/**
 * @notice The AbstractModule contract
 *
 * The AbstractModule contract provides a framework for implementing compliance modules.
 *
 * Each module is capable of matching claim topics to corresponding handlers, with claim topics organized under user-defined claim topic keys.
 *
 * Here are some examples illustrating how modules could be setup.
 *
 * 1. KYC Verification:
 *
 * TransferSender <claimTopicKey> =>
 *   KYCed <claimTopic> => _handleKYCed <handler>
 *   LegalAge <claimTopic> => _handleLegalAge <handler>
 *
 * In this example, whenever a transfer occurs, the compliance module checks if the sender is KYC compliant
 * and of legal age. Corresponding handlers `_handleIsKYCed` and `_handleCountryCheck` are invoked to execute
 * the necessary checks, allowing the transfer to proceed.
 *
 * 2. Mint Amount Verification:
 *
 * Transfer <claimTopicKey> =>
 *   MinTransferLimit <claimTopic> => _handleMinTransferLimit <handler>
 *   MaxTransferLimit <claimTopic> => _handleMaxTransferLimit <handler>
 * TransferFrom <claimTopicKey> =>
 *   MinTransferLimit <claimTopic> => _handleMinTransferLimit <handler>
 *   MaxTransferLimit <claimTopic> => _handleMaxTransferLimit <handler>
 *
 * In this scenario, when a new token is being transferred, the `_handleMinTransferLimit` and `_handleMaxTransferLimit`
 * handlers are triggered to verify if the minted amount falls within predefined transfer limits.
 */
abstract contract AbstractModule is Initializable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SetHelper for EnumerableSet.Bytes32Set;

    struct Handler {
        bool isHandlerSet;
        function(TokenF.Context memory) internal view returns (bool) handler;
    }

    modifier onlyRole(bytes32 role_) {
        _onlyRole(role_);
        _;
    }

    address private _tokenF;

    mapping(bytes32 claimTopicKey => EnumerableSet.Bytes32Set claimTopics) private _claimTopics;
    mapping(bytes32 claimTopic => Handler handler) private _handlers;

    function __AbstractComplianceModule_init(address tokenF_) internal onlyInitializing {
        _tokenF = tokenF_;

        _handlerer();
    }

    function _handlerer() internal virtual;

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
        _claimTopics[claimTopicKey_].strictAdd(claimTopics_);
    }

    function _removeClaimTopics(
        bytes32 claimTopicKey_,
        bytes32[] memory claimTopics_
    ) internal virtual {
        _claimTopics[claimTopicKey_].strictRemove(claimTopics_);
    }

    function _setHandler(
        bytes32 claimTopic_,
        function(TokenF.Context memory) internal view returns (bool) handler_
    ) internal virtual {
        Handler storage _handler = _handlers[claimTopic_];

        _handler.isHandlerSet = true;
        _handler.handler = handler_;
    }

    function _handle(TokenF.Context calldata ctx_) internal view virtual returns (bool) {
        TokenF.Context[] memory ctxs_ = _getExtContexts(ctx_);

        for (uint256 i = 0; i < ctxs_.length; ++i) {
            bytes32 claimTopicKey_ = _getClaimTopicKey(ctxs_[i]);
            bytes32[] memory claimTopics_ = getClaimTopics(claimTopicKey_);

            for (uint256 j = 0; j < claimTopics_.length; ++j) {
                /*
                 * TODO: This handler cannot be called externally with `ctxs_[i]` passed as `TokenF.Context calldata`.
                 * Furthermore, `ctx_` is taken as `TokenF.Context calldata` to explicitly avoid reference issues while copying
                 * `ctx_` in `_getExtContexts`. The temporary solution is to simply pass `ctxs_[i]` as `TokenF.Context memory` here.
                 */
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
        Handler storage _handler = _handlers[claimTopic_];

        require(_handler.isHandlerSet, "AModule: handler is not set");

        return _handler.handler;
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
