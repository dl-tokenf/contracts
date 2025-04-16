// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

abstract contract NFTFStorage {
    bytes32 internal constant NFT_F_STORAGE_SLOT = keccak256("tokenf.standard.nftf.storage");

    struct NftFStorage {
        string baseURI;
        mapping(uint256 tokenId => string) tokenURIs;
    }

    function _getNftFStorage() internal pure returns (NftFStorage storage _nftfStorage) {
        bytes32 slot_ = NFT_F_STORAGE_SLOT;

        assembly {
            _nftfStorage.slot := slot_
        }
    }
}
