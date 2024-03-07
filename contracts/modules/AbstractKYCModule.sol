// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenF} from "../core/TokenF.sol";

import {AbstractComplianceModule} from "./AbstractComplianceModule.sol";

abstract contract AbstractKYCModule is AbstractComplianceModule {
    enum TransferParty {
        Sender,
        Recipient,
        Operator
    }

    function isKYCed(TokenF.Context calldata ctx_) public view virtual returns (bool) {
        return _hook(ctx_);
    }

    function _getExtContexts(
        TokenF.Context calldata ctx_
    ) internal view virtual override returns (TokenF.Context[] memory) {
        TokenF.Context[] memory ctxs_ = new TokenF.Context[](3);
        ctxs_[0] = _getExtContext(ctx_, TransferParty.Sender);
        ctxs_[1] = _getExtContext(ctx_, TransferParty.Recipient);
        ctxs_[2] = _getExtContext(ctx_, TransferParty.Operator);

        return ctxs_;
    }

    function _getClaimTopicKey(
        TokenF.Context memory ctx_
    ) internal view virtual override returns (bytes32) {
        TransferParty transferParty_ = abi.decode(ctx_.data, (TransferParty));

        return keccak256(abi.encodePacked(ctx_.selector, transferParty_));
    }

    function _getExtContext(
        TokenF.Context calldata ctx_,
        TransferParty transferParty_
    ) private pure returns (TokenF.Context memory extCtx_) {
        extCtx_ = ctx_;
        extCtx_.data = abi.encode(transferParty_);
    }

    uint256[50] private _gap;
}
