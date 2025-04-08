// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SetHelper} from "@solarity/solidity-lib/libs/arrays/SetHelper.sol";

import {IAgentAccessControl} from "../interfaces/IAgentAccessControl.sol";

import {IAssetF} from "../interfaces/IAssetF.sol";

/**
 * @notice The `AbstractModule` contract
 *
 * The `AbstractModule` contract provides a framework for implementing compliance modules.
 *
 * Each module is capable of matching handler topics to corresponding handlers, with handler topics organized under
 * user-defined context keys.
 */
abstract contract AbstractModule is Initializable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SetHelper for EnumerableSet.Bytes32Set;

    struct Handler {
        bool isHandlerSet;
        function(IAssetF.Context memory) internal view returns (bool) handler;
    }

    modifier onlyRole(bytes32 role_) {
        _onlyRole(role_);
        _;
    }

    address private _assetF;

    mapping(bytes32 contextKey => EnumerableSet.Bytes32Set handlerTopics) private _handlerTopics;
    mapping(bytes32 handlerTopic => Handler handler) private _handlers;

    error HandlerNotSet();

    function __AbstractModule_init(address assetF_) internal onlyInitializing {
        _assetF = assetF_;

        _handlerer();
    }

    /**
     * @notice Function for adding an array of handler topics for the corresponding context key.
     *
     * This function in the basic `TokenF` and `NFTF` implementations can only be called by users who have the Agent role.
     *
     * An internal function `_complianceModuleRole` is used to retrieve the role that is used in the validation,
     * which can be overridden if you want to use a role other than Agent.
     *
     * @param contextKey_ The key of the handler topics
     * @param handlerTopics_ Array of handler topics to add
     */
    function addHandlerTopics(
        bytes32 contextKey_,
        bytes32[] memory handlerTopics_
    ) public virtual onlyRole(_moduleRole()) {
        _addHandlerTopics(contextKey_, handlerTopics_);
    }

    /**
     * @notice Function for removing an array of handler topics from the list of the corresponding context key.
     *
     * This function in basic `TokenF` and `NFTF` implementation can only be called by users who have the Agent role.
     *
     * An internal function `_complianceModuleRole` is used to retrieve the role that is used in the validation,
     * which can be overridden if you want to use a role other than Agent.
     *
     * @param contextKey_ The key of the handler topics
     * @param handlerTopics_ Array of handler topics to be removed
     */
    function removeHandlerTopics(
        bytes32 contextKey_,
        bytes32[] memory handlerTopics_
    ) public virtual onlyRole(_moduleRole()) {
        _removeHandlerTopics(contextKey_, handlerTopics_);
    }

    /**
     * @notice Function to retrieve all stored handler topics by the passed context key.
     *
     * @param contextKey_ The key of the handler topics for which the array should be obtained
     * @return handler topics array
     */
    function getHandlerTopics(bytes32 contextKey_) public view virtual returns (bytes32[] memory) {
        return _handlerTopics[contextKey_].values();
    }

    /**
     * @notice Function to retrieve the address of the corresponding `TokenF` or `NFTF` contract to which this module contract is bound.
     *
     * @return address of `TokenF` or `NFTF` contract
     */
    function getAssetF() public view virtual returns (address) {
        return _assetF;
    }

    /**
     * @notice Internal function to add an array of handler topics for the passed context key.
     *
     * In case it is necessary to change or extend the logic of adding handler topics,
     * you can override this function and make any necessary changes.
     *
     * @param contextKey_ The context key
     * @param handlerTopics_ The array of handler topics to add
     */
    function _addHandlerTopics(
        bytes32 contextKey_,
        bytes32[] memory handlerTopics_
    ) internal virtual {
        _handlerTopics[contextKey_].strictAdd(handlerTopics_);
    }

    /**
     * @notice Internal function to remove the handler topics array for the passed context key.
     *
     * In case you want to change or extend the logic of deleting handler topics,
     * you can override this function and make any necessary changes.
     *
     * @param contextKey_ The context key
     * @param handlerTopics_ The array of handler topics to be removed
     */
    function _removeHandlerTopics(
        bytes32 contextKey_,
        bytes32[] memory handlerTopics_
    ) internal virtual {
        _handlerTopics[contextKey_].strictRemove(handlerTopics_);
    }

    /**
     * @notice Function to save a function handler to a storage by a specific key.
     * Often this function will be used in pair with the `_handlerer` function.
     *
     * If you need to extend the logic, you can also override this function.
     *
     * @param handlerTopic_ The label of the topic for which the handler is to be set
     * @param handler_ Pointer to the handler function
     */
    function _setHandler(
        bytes32 handlerTopic_,
        function(IAssetF.Context memory) internal view returns (bool) handler_
    ) internal virtual {
        Handler storage _handler = _handlers[handlerTopic_];

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
     *         _setHandler(<YOUR_HANDLER_TOPIC>, _yourHandlerFunc);
     *     }
     * ```
     */
    function _handlerer() internal virtual;

    /**
     * @notice Function to retrieve the context key from the transaction context.
     *
     * The `bytes32` type has been chosen for the context key so that it could be customised.
     * Depending on the future purpose of the module, it will be possible to define the process of creating a context key,
     * which allows the modules to be quite flexible.
     *
     * By default, the context key is a hash of the function selector, i.e. the module is able to define different
     * rules for different functions.
     *
     * @param ctx_ The transaction context
     * @return context key
     */
    function _getContextKey(IAssetF.Context memory ctx_) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked(ctx_.selector));
    }

    /**
     * @notice The main function to process the passed transaction context.
     *
     * Within it, all the set of handler topics are retrieved by the context key.
     * Then for each handler topic a handler function is obtained, which processes the passed context.
     *
     * @param ctx_ The transaction context
     */
    function _handle(IAssetF.Context memory ctx_) internal view virtual returns (bool) {
        bytes32 contextKey_ = _getContextKey(ctx_);
        bytes32[] memory handlerTopics_ = getHandlerTopics(contextKey_);

        for (uint256 j = 0; j < handlerTopics_.length; ++j) {
            if (!_getHandler(handlerTopics_[j])(ctx_)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Function to retrieve a previously saved handler function by handler topic.
     *
     * In case no function handler has been set for the passed handler topic,
     * transaction will fail with the error - `HandlerNotSet()`.
     *
     * @param handlerTopic_ The handler topic for which a handler function is to be retrieved
     * @return pointer to the previously saved handler function
     */
    function _getHandler(
        bytes32 handlerTopic_
    )
        internal
        view
        virtual
        returns (function(IAssetF.Context memory) internal view returns (bool))
    {
        Handler storage _handler = _handlers[handlerTopic_];

        require(_handler.isHandlerSet, HandlerNotSet());

        return _handler.handler;
    }

    function _moduleRole() internal view virtual returns (bytes32) {
        return IAgentAccessControl(_assetF).AGENT_ROLE();
    }

    function _onlyRole(bytes32 role_) internal view virtual {
        IAgentAccessControl(_assetF).checkRole(role_, msg.sender);
    }

    uint256[47] private _gap;
}
