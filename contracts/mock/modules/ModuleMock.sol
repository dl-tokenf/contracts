// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../../core/TokenF.sol";
import {AbstractRegulatoryModule} from "../../modules/AbstractRegulatoryModule.sol";
import {AbstractKYCModule} from "../../modules/AbstractKYCModule.sol";

contract ModuleMock is AbstractRegulatoryModule, AbstractKYCModule {
    bytes32 public constant MOCK_TOPIC = keccak256("MOCK");

    function __ModuleMock_init(address tokenF_) external initializer {
        __AbstractModule_init(tokenF_);
        __AbstractRegulatoryModule_init();
        __AbstractKYCModule_init();
    }

    function _handlerer() internal override {}

    function handlerer() external {
        _setHandler(MOCK_TOPIC, _handleMockTopic);
    }

    function __AbstractModuleDirect_init() external {
        __AbstractModule_init(address(0));
    }

    function __AbstractRegulatoryModuleDirect_init() external {
        __AbstractRegulatoryModule_init();
    }

    function __AbstractKYCModuleDirect_init() external {
        __AbstractKYCModule_init();
    }

    function getClaimTopicKey(bytes4 selector_) external view returns (bytes32) {
        TokenF.Context memory ctx_;
        ctx_.selector = selector_;

        return _getClaimTopicKey(ctx_);
    }

    function _handleMockTopic(TokenF.Context memory) internal view virtual returns (bool) {
        return true;
    }
}
