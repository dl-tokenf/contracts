// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SetHelper} from "@solarity/solidity-lib/libs/arrays/SetHelper.sol";

import {IAgentAccessControl} from "../interfaces/IAgentAccessControl.sol";

import {TokenF} from "../core/TokenF.sol";

/**
 * @notice The `AbstractModule` contract
 *
 * The `AbstractModule` contract provides a framework for implementing compliance modules.
 *
 * Each module is capable of matching claim topics to corresponding handlers, with claim topics organized under
 * user-defined claim topic keys.
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

    function __AbstractModule_init(address tokenF_) internal onlyInitializing {
        _tokenF = tokenF_;

        _handlerer();
    }

    /**
     * @notice Function for adding an array of claim topics for the corresponding claim topic key.
     *
     * This function in the basic `TokenF` implementation can only be called by users who have the Agent role.
     *
     * An internal function `_complianceModuleRole` is used to retrieve the role that is used in the validation,
     * which can be overridden if you want to use a role other than Agent.
     *
     * @param claimTopicKey_ The key of the claim topics
     * @param claimTopics_ Array of claim topics to add
     */
    function addClaimTopics(
        bytes32 claimTopicKey_,
        bytes32[] memory claimTopics_
    ) public virtual onlyRole(_complianceModuleRole()) {
        _addClaimTopics(claimTopicKey_, claimTopics_);
    }

    /**
     * @notice Function for removing an array of claim topics from the list of the corresponding claim topic key.
     *
     * This function in the basic `TokenF` implementation can only be called by users who have the Agent role.
     *
     * An internal function `_complianceModuleRole` is used to retrieve the role that is used in the validation,
     * which can be overridden if you want to use a role other than Agent.
     *
     * @param claimTopicKey_ The key of the claim topics
     * @param claimTopics_ Array of claim topics to be removed
     */
    function removeClaimTopics(
        bytes32 claimTopicKey_,
        bytes32[] memory claimTopics_
    ) public virtual onlyRole(_complianceModuleRole()) {
        _removeClaimTopics(claimTopicKey_, claimTopics_);
    }

    /**
     * @notice Function to retrieve all stored claim topics by the passed claim topic key.
     *
     * @param claimTopicsKey_ The key of the claim topics for which the array should be obtained
     * @return claim topics array
     */
    function getClaimTopics(
        bytes32 claimTopicsKey_
    ) public view virtual returns (bytes32[] memory) {
        return _claimTopics[claimTopicsKey_].values();
    }

    /**
     * @notice Function to get the `TokenF` address of the contract to which this module contract is bound.
     *
     * @return address of `TokenF` contract
     */
    function getTokenF() public view virtual returns (address) {
        return _tokenF;
    }

    /**
     * @notice Internal function to add an array of claim topics for the passed claim topic key.
     *
     * In case it is necessary to change or extend the logic of adding claim topics,
     * you can override this function and make any necessary changes.
     *
     * @param claimTopicKey_ The claim topic key
     * @param claimTopics_ The array of claim topics to add
     */
    function _addClaimTopics(
        bytes32 claimTopicKey_,
        bytes32[] memory claimTopics_
    ) internal virtual {
        _claimTopics[claimTopicKey_].strictAdd(claimTopics_);
    }

    /**
     * @notice Internal function to remove the claim topics array for the passed claim topic key.
     *
     * In case you want to change or extend the logic of deleting claim topics,
     * you can override this function and make any necessary changes.
     *
     * @param claimTopicKey_ The claim topic key
     * @param claimTopics_ The array of claim topicsto be removed
     */
    function _removeClaimTopics(
        bytes32 claimTopicKey_,
        bytes32[] memory claimTopics_
    ) internal virtual {
        _claimTopics[claimTopicKey_].strictRemove(claimTopics_);
    }

    /**
     * @notice Function to save a function handler to a storedge by a specific key.
     * Often this function will be used in pair with the `_handlerer` function.
     *
     * If you need to extend the logic, you can also override this function.
     *
     * @param claimTopic_ The label of the topic for which the handler is to be set
     * @param handler_ Pointer to the handler function
     */
    function _setHandler(
        bytes32 claimTopic_,
        function(TokenF.Context memory) internal view returns (bool) handler_
    ) internal virtual {
        Handler storage _handler = _handlers[claimTopic_];

        _handler.isHandlerSet = true;
        _handler.handler = handler_;
    }

    /**
     * @notice Function that sets internally all existing handlers in the storage.
     *
     * When adding new handlers, you must override this function with a call to `super._handlerer()` inside the new implementation,
     * so as not to lose any handlers already configured.
     *
     * An example of a possible implementation:
     *
     * ```solidity
     *     function _handlerer() internal virtual override {
     *         _setHandler(<YOUR_CLAIM_TOPIC>, _yourHandlerFunc);
     *     }
     * ```
     */
    function _handlerer() internal virtual;

    /**
     * @notice Function to retrieve the claim topic key from the transaction context.
     *
     * The `bytes32` type has been chosen for the claim topic key so that it could be customised.
     * Depending on the future purpose of the module, it will be possible to define the process of creating a claim topic key,
     * which allows the modules to be quite flexible.
     *
     * An example of a possible implementation, where the claim topic key is a hash of the function selector,
     * i.e. the module only needs to be able to define different rules for different functions:
     *
     * ```solidity
     *     function _getClaimTopicKey(
     *         TokenF.Context memory ctx_
     *     ) internal view virtual override returns (bytes32) {
     *         return keccak256(abi.encodePacked(ctx_.selector));
     *     }
     * ```
     *
     * @param ctx_ The transaction context
     * @return claim topic key
     */
    function _getClaimTopicKey(TokenF.Context memory ctx_) internal view virtual returns (bytes32);

    /**
     * @notice The main function to process the passed transaction context.
     *
     * Within it, all the set claim topics are retrieved by the claim topic key.
     * Then for each claim topic a handler function is obtained, which processes the passed context.
     *
     * @param ctx_ The transaction context
     */
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

    /**
     * @notice Function to retrieve a previously saved handler function by claim topic.
     *
     * In case no function handler has been set for the passed claim topic,
     * transaction will fail with the error - `AModule: handler is not set`.
     *
     * @param claimTopic_ The claim topic for which a handler function is to be retrieved
     * @return pointer to the previously saved handler function
     */
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

    /**
     * @notice The function is required to extend the main context of the transaction.
     *
     * In case when it is necessary to make several checks for different parts of the transaction,
     * it is necessary to have corresponding contexts for each check. This is what this function is for.
     *
     * For example in the case of KYC checks it may be necessary to have different checks for different transferParties (from, to or operator).
     * In this way it is possible to extend the contexts and add transferParty information to the data field:
     *
     * ```solidity
     *     function _getExtContexts(
     *         TokenF.Context calldata ctx_
     *     ) internal view virtual override returns (TokenF.Context[] memory) {
     *         TokenF.Context[] memory ctxs_ = new TokenF.Context[](3);
     *         ctxs_[0] = _getExtContext(ctx_, TransferParty.Sender);
     *         ctxs_[1] = _getExtContext(ctx_, TransferParty.Recipient);
     *         ctxs_[2] = _getExtContext(ctx_, TransferParty.Operator);
     *
     *         return ctxs_;
     *     }
     * ```
     *
     * @param ctx_ The initial transaction context
     * @return array of extended contexts
     */
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
