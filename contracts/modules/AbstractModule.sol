// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SetHelper} from "@solarity/solidity-lib/libs/arrays/SetHelper.sol";

import {IAgentAccessControl} from "../interfaces/IAgentAccessControl.sol";

import {Context} from "../core/Globals.sol";

/**
 * @notice The `AbstractModule` contract
 *
 * The `AbstractModule` contract provides a framework for implementing compliance modules.
 *
 * Each module is capable of matching handle topics to corresponding handlers, with handle topics organized under
 * user-defined handle topic keys.
 */
abstract contract AbstractModule is Initializable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SetHelper for EnumerableSet.Bytes32Set;

    struct Handler {
        bool isHandlerSet;
        function(Context memory) internal view returns (bool) handler;
    }

    modifier onlyRole(bytes32 role_) {
        _onlyRole(role_);
        _;
    }

    address private _tokenF;

    mapping(bytes32 contextKey => EnumerableSet.Bytes32Set handleTopics) private _handleTopics;
    mapping(bytes32 handleTopic => Handler handler) private _handlers;

    error HandlerNotSet();

    function __AbstractModule_init(address tokenF_) internal onlyInitializing {
        _tokenF = tokenF_;

        _handlerer();
    }

    /**
     * @notice Function for adding an array of handle topics for the corresponding context key.
     *
     * This function in the basic `TokenF` implementation can only be called by users who have the Agent role.
     *
     * An internal function `_complianceModuleRole` is used to retrieve the role that is used in the validation,
     * which can be overridden if you want to use a role other than Agent.
     *
     * @param contextKey_ The key of the handle topics
     * @param handleTopics_ Array of handle topics to add
     */
    function addHandleTopics(
        bytes32 contextKey_,
        bytes32[] memory handleTopics_
    ) public virtual onlyRole(_moduleRole()) {
        _addHandleTopics(contextKey_, handleTopics_);
    }

    /**
     * @notice Function for removing an array of handle topics from the list of the corresponding context key.
     *
     * This function in the basic `TokenF` implementation can only be called by users who have the Agent role.
     *
     * An internal function `_complianceModuleRole` is used to retrieve the role that is used in the validation,
     * which can be overridden if you want to use a role other than Agent.
     *
     * @param contextKey_ The key of the handle topics
     * @param handleTopics_ Array of handle topics to be removed
     */
    function removeHandleTopics(
        bytes32 contextKey_,
        bytes32[] memory handleTopics_
    ) public virtual onlyRole(_moduleRole()) {
        _removeHandleTopics(contextKey_, handleTopics_);
    }

    /**
     * @notice Function to retrieve all stored handle topics by the passed context key.
     *
     * @param contextKey_ The key of the handle topics for which the array should be obtained
     * @return handle topics array
     */
    function getHandleTopics(bytes32 contextKey_) public view virtual returns (bytes32[] memory) {
        return _handleTopics[contextKey_].values();
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
     * @notice Internal function to add an array of handle topics for the passed context key.
     *
     * In case it is necessary to change or extend the logic of adding handle topics,
     * you can override this function and make any necessary changes.
     *
     * @param contextKey_ The context key
     * @param handleTopics_ The array of handle topics to add
     */
    function _addHandleTopics(
        bytes32 contextKey_,
        bytes32[] memory handleTopics_
    ) internal virtual {
        _handleTopics[contextKey_].strictAdd(handleTopics_);
    }

    /**
     * @notice Internal function to remove the handle topics array for the passed context key.
     *
     * In case you want to change or extend the logic of deleting handle topics,
     * you can override this function and make any necessary changes.
     *
     * @param contextKey_ The context key
     * @param handleTopics_ The array of handle topics to be removed
     */
    function _removeHandleTopics(
        bytes32 contextKey_,
        bytes32[] memory handleTopics_
    ) internal virtual {
        _handleTopics[contextKey_].strictRemove(handleTopics_);
    }

    /**
     * @notice Function to save a function handler to a storage by a specific key.
     * Often this function will be used in pair with the `_handlerer` function.
     *
     * If you need to extend the logic, you can also override this function.
     *
     * @param handleTopic_ The label of the topic for which the handler is to be set
     * @param handler_ Pointer to the handler function
     */
    function _setHandler(
        bytes32 handleTopic_,
        function(Context memory) internal view returns (bool) handler_
    ) internal virtual {
        Handler storage _handler = _handlers[handleTopic_];

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
     *         _setHandler(<YOUR_HANDLE_TOPIC>, _yourHandlerFunc);
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
    function _getContextKey(Context memory ctx_) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked(ctx_.selector));
    }

    /**
     * @notice The main function to process the passed transaction context.
     *
     * Within it, all the set of handle topics are retrieved by the context key.
     * Then for each handle topic a handler function is obtained, which processes the passed context.
     *
     * @param ctx_ The transaction context
     */
    function _handle(Context memory ctx_) internal view virtual returns (bool) {
        bytes32 contextKey_ = _getContextKey(ctx_);
        bytes32[] memory handleTopics_ = getHandleTopics(contextKey_);

        for (uint256 j = 0; j < handleTopics_.length; ++j) {
            if (!_getHandler(handleTopics_[j])(ctx_)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Function to retrieve a previously saved handler function by handle topic.
     *
     * In case no function handler has been set for the passed handle topic,
     * transaction will fail with the error - `HandlerNotSet()`.
     *
     * @param handleTopic_ The handle topic for which a handler function is to be retrieved
     * @return pointer to the previously saved handler function
     */
    function _getHandler(
        bytes32 handleTopic_
    ) internal view virtual returns (function(Context memory) internal view returns (bool)) {
        Handler storage _handler = _handlers[handleTopic_];

        require(_handler.isHandlerSet, HandlerNotSet());

        return _handler.handler;
    }

    function _moduleRole() internal view virtual returns (bytes32) {
        return IAgentAccessControl(_tokenF).AGENT_ROLE();
    }

    function _onlyRole(bytes32 role_) internal view virtual {
        IAgentAccessControl(_tokenF).checkRole(role_, msg.sender);
    }

    uint256[47] private _gap;
}
