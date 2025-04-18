// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {ERC721EnumerableUpgradeable, ERC721Upgradeable, IERC165} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import {IAssetF, INFTF} from "./interfaces/INFTF.sol";
import {IKYCCompliance} from "./interfaces/core/IKYCCompliance.sol";
import {IRegulatoryCompliance} from "./interfaces/core/IRegulatoryCompliance.sol";

import {AbstractAssetF} from "./AbstractAssetF.sol";
import {AccessControlUpgradeable} from "./core/AgentAccessControl.sol";
import {NFTFStorage} from "./storages/NFTFStorage.sol";

abstract contract NFTF is INFTF, AbstractAssetF, NFTFStorage, ERC721EnumerableUpgradeable {
    bytes4 public constant TRANSFER_SELECTOR = this.transfer.selector;
    bytes4 public constant TRANSFER_FROM_SELECTOR = this.transferFrom.selector;
    bytes4 public constant MINT_SELECTOR = this.mint.selector;
    bytes4 public constant BURN_SELECTOR = this.burn.selector;
    bytes4 public constant FORCED_TRANSFER_SELECTOR = this.forcedTransfer.selector;

    function __NFTF_init(
        address regulatoryCompliance_,
        address kycCompliance_,
        bytes memory initRegulatory_,
        bytes memory initKYC_
    ) internal virtual onlyInitializing {
        __AbstractAssetF_init(regulatoryCompliance_, kycCompliance_, initRegulatory_, initKYC_);
    }

    /// @inheritdoc INFTF
    function transfer(address to_, uint256 tokenId_) public virtual override {
        _canTransfer(msg.sender, to_, tokenId_, address(0));
        _isKYCed(msg.sender, to_, tokenId_, address(0));

        super._transfer(msg.sender, to_, tokenId_);

        _transferred(msg.sender, to_, tokenId_, address(0));
    }

    /// @inheritdoc IERC721
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual override(ERC721Upgradeable, IERC721) {
        _canTransfer(from_, to_, tokenId_, msg.sender);
        _isKYCed(from_, to_, tokenId_, msg.sender);

        super.transferFrom(from_, to_, tokenId_);

        _transferred(from_, to_, tokenId_, msg.sender);
    }

    /// @inheritdoc INFTF
    function mint(
        address account_,
        uint256 tokenId_,
        string memory tokenURI_
    ) public virtual override onlyRole(_mintRole()) {
        _canTransfer(address(0), account_, tokenId_, msg.sender);
        _isKYCed(address(0), account_, tokenId_, msg.sender);

        super._mint(account_, tokenId_);
        _setTokenURI(tokenId_, tokenURI_);

        _transferred(address(0), account_, tokenId_, msg.sender);
    }

    /// @inheritdoc INFTF
    function burn(uint256 tokenId_) public virtual override onlyRole(_burnRole()) {
        address account_ = _ownerOf(tokenId_);

        _canTransfer(account_, address(0), tokenId_, msg.sender);
        _isKYCed(account_, address(0), tokenId_, msg.sender);

        super._burn(tokenId_);

        _transferred(account_, address(0), tokenId_, msg.sender);
    }

    /// @inheritdoc INFTF
    function forcedTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual override onlyRole(_forcedTransferRole()) {
        _canTransfer(from_, to_, tokenId_, msg.sender);
        _isKYCed(from_, to_, tokenId_, msg.sender);

        super._transfer(from_, to_, tokenId_);

        _transferred(from_, to_, tokenId_, msg.sender);
    }

    /// @inheritdoc IAssetF
    function recovery(
        address oldAccount_,
        address newAccount_
    ) public virtual override onlyRole(_recoveryRole()) returns (bool) {
        uint256 oldBalance_ = balanceOf(oldAccount_);

        for (uint256 i = oldBalance_; i > 0; --i) {
            uint256 tokenId_ = tokenOfOwnerByIndex(oldAccount_, i - 1);

            _canTransfer(oldAccount_, newAccount_, tokenId_, msg.sender);
            _isKYCed(oldAccount_, newAccount_, tokenId_, msg.sender);

            super._transfer(oldAccount_, newAccount_, tokenId_);

            _transferred(oldAccount_, newAccount_, tokenId_, msg.sender);
        }

        return true;
    }

    /// @inheritdoc INFTF
    function setBaseURI(string memory baseURI_) public virtual override onlyRole(_uriRole()) {
        _getNftFStorage().baseURI = baseURI_;
    }

    /// @inheritdoc INFTF
    function setTokenURI(
        uint256 tokenId_,
        string memory tokenURI_
    ) public virtual override onlyRole(_uriRole()) {
        _requireOwned(tokenId_);

        _setTokenURI(tokenId_, tokenURI_);
    }

    /**
     * @inheritdoc IERC721Metadata
     *
     * @dev
     * If the token does not exist, an empty string is returned.
     * If a tokenURI is set for the token, it will be returned.
     * If a base URI is set, the concatenation of the base URI and tokenId is returned.
     * Otherwise, an empty string is returned.
     */
    function tokenURI(
        uint256 tokenId_
    ) public view virtual override(IERC721Metadata, ERC721Upgradeable) returns (string memory) {
        address owner_ = _ownerOf(tokenId_);

        if (owner_ == address(0)) {
            return "";
        }

        NftFStorage storage $ = _getNftFStorage();
        string memory tokenURI_ = $.tokenURIs[tokenId_];

        if (bytes(tokenURI_).length > 0) {
            return tokenURI_;
        }

        return super.tokenURI(tokenId_);
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId_
    )
        public
        view
        override(AccessControlUpgradeable, ERC721EnumerableUpgradeable, IERC165)
        returns (bool)
    {
        return interfaceId_ == type(INFTF).interfaceId || super.supportsInterface(interfaceId_);
    }

    function _setTokenURI(uint256 tokenId_, string memory tokenURI_) internal virtual {
        NftFStorage storage $ = _getNftFStorage();
        $.tokenURIs[tokenId_] = tokenURI_;

        emit MetadataUpdate(tokenId_);
    }

    function _transferred(
        address from_,
        address to_,
        uint256 tokenId_,
        address operator_
    ) internal virtual {
        try
            IRegulatoryCompliance(address(this)).transferred(
                Context(bytes4(bytes(msg.data[:4])), from_, to_, 0, tokenId_, operator_, "")
            )
        {} catch {
            revert TransferredReverted();
        }
    }

    function _canTransfer(
        address from_,
        address to_,
        uint256 tokenId_,
        address operator_
    ) internal view virtual {
        try
            IRegulatoryCompliance(address(this)).canTransfer(
                Context(bytes4(bytes(msg.data[:4])), from_, to_, 0, tokenId_, operator_, "")
            )
        returns (bool canTransfer_) {
            require(canTransfer_, CannotTransfer());
        } catch {
            revert CanTransferReverted();
        }
    }

    function _isKYCed(
        address from_,
        address to_,
        uint256 tokenId_,
        address operator_
    ) internal view virtual {
        try
            IKYCCompliance(address(this)).isKYCed(
                Context(bytes4(bytes(msg.data[:4])), from_, to_, 0, tokenId_, operator_, "")
            )
        returns (bool isKYCed_) {
            require(isKYCed_, NotKYCed());
        } catch {
            revert IsKYCedReverted();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _getNftFStorage().baseURI;
    }

    function _uriRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }
}
