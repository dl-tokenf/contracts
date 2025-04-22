// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {NFTF} from "@tokenf/contracts/NFTF.sol";

contract LandNFT is NFTF {
    function __LandNFT_init(
        address regulatoryCompliance_,
        address kycCompliance_,
        bytes memory initRegulatory_,
        bytes memory initKYC_
    ) external initializer {
        __AccessControl_init();
        __ERC721_init("Land NFT", "LNFT");
        __AgentAccessControl_init();
        __NFTF_init(regulatoryCompliance_, kycCompliance_, initRegulatory_, initKYC_);
    }
}
