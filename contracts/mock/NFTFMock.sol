// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {NFTF} from "../NFTF.sol";

contract NFTFMock is NFTF {
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant FORCED_TRANSFER_ROLE = keccak256("FORCED_TRANSFER_ROLE");
    bytes32 public constant RECOVERY_ROLE = keccak256("RECOVERY_ROLE");
    bytes32 public constant URI_ROLE = keccak256("URI_ROLE");
    bytes32 public constant DIAMOND_CUT_ROLE = keccak256("DIAMOND_CUT_ROLE");

    function __NFTFMock_init(
        string memory name_,
        string memory symbol_,
        address rCompliance_,
        address kycCompliance_,
        bytes memory initRegulatory_,
        bytes memory initKYC_
    ) external initializer {
        __AccessControl_init();
        __ERC721_init(name_, symbol_);
        __AgentAccessControl_init();
        __NFTF_init(rCompliance_, kycCompliance_, initRegulatory_, initKYC_);
    }

    function __NFTFDirect_init() external {
        __NFTF_init(address(0), address(0), "", "");
    }

    function defaultMintRole() external view returns (bytes32) {
        return super._mintRole();
    }

    function defaultBurnRole() external view returns (bytes32) {
        return super._burnRole();
    }

    function defaultForcedTransferRole() external view returns (bytes32) {
        return super._forcedTransferRole();
    }

    function defaultRecoveryRole() external view returns (bytes32) {
        return super._recoveryRole();
    }

    function defaultUriRole() external view returns (bytes32) {
        return super._uriRole();
    }

    function defaultDiamondCutRole() external view returns (bytes32) {
        return super._diamondCutRole();
    }

    function _mintRole() internal pure override returns (bytes32) {
        return MINT_ROLE;
    }

    function _burnRole() internal pure override returns (bytes32) {
        return BURN_ROLE;
    }

    function _forcedTransferRole() internal pure override returns (bytes32) {
        return FORCED_TRANSFER_ROLE;
    }

    function _recoveryRole() internal pure override returns (bytes32) {
        return RECOVERY_ROLE;
    }

    function _uriRole() internal pure override returns (bytes32) {
        return URI_ROLE;
    }

    function _diamondCutRole() internal pure override returns (bytes32) {
        return DIAMOND_CUT_ROLE;
    }
}
