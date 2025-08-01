// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IAssetF} from "../../interfaces/IAssetF.sol";
import {AbstractRegulatoryModule} from "../../modules/AbstractRegulatoryModule.sol";
import {AbstractKYCModule} from "../../modules/AbstractKYCModule.sol";

contract ModuleMock is AbstractRegulatoryModule, AbstractKYCModule {
    bytes32 public constant MOCK_TOPIC = keccak256("MOCK");

    function __ModuleMock_init(address assetF_) external initializer {
        __AbstractModule_init(assetF_);
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

    function getContextKeyBySelector(bytes4 selector_) external view returns (bytes32) {
        IAssetF.Context memory ctx_;
        ctx_.selector = selector_;

        return _getContextKey(ctx_);
    }

    function _handleMockTopic(IAssetF.Context memory) internal view virtual returns (bool) {
        return true;
    }
}
