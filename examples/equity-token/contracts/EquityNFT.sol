// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {NFTF} from "@tokenf/contracts/core/NFTF.sol";

contract EquityNFT is NFTF {
    function __EquityNFT_init(
        address regulatoryCompliance_,
        address kycCompliance_,
        bytes memory initRegulatory_,
        bytes memory initKYC_
    ) external initializer {
        __AccessControl_init();
        __ERC721_init("Equity NFT", "ENFT");
        __AgentAccessControl_init();
        __NFTF_init(regulatoryCompliance_, kycCompliance_, initRegulatory_, initKYC_);
    }
}
