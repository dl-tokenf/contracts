// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {IAssetF, ITokenF} from "./interfaces/ITokenF.sol";
import {IKYCCompliance} from "./interfaces/core/IKYCCompliance.sol";
import {IRegulatoryCompliance} from "./interfaces/core/IRegulatoryCompliance.sol";

import {AbstractAssetF} from "./AbstractAssetF.sol";
import {TokenFStorage} from "./storages/TokenFStorage.sol";

abstract contract TokenF is ITokenF, AbstractAssetF, TokenFStorage, ERC20Upgradeable {
    bytes4 public constant TRANSFER_SELECTOR = this.transfer.selector;
    bytes4 public constant TRANSFER_FROM_SELECTOR = this.transferFrom.selector;
    bytes4 public constant MINT_SELECTOR = this.mint.selector;
    bytes4 public constant BURN_SELECTOR = this.burn.selector;
    bytes4 public constant FORCED_TRANSFER_SELECTOR = this.forcedTransfer.selector;

    function __TokenF_init(
        address regulatoryCompliance_,
        address kycCompliance_,
        bytes memory initRegulatory_,
        bytes memory initKYC_
    ) internal virtual onlyInitializing {
        __AbstractAssetF_init(regulatoryCompliance_, kycCompliance_, initRegulatory_, initKYC_);
    }

    /// @inheritdoc IERC20
    function transfer(
        address to_,
        uint256 amount_
    ) public virtual override(ERC20Upgradeable, IERC20) returns (bool) {
        _canTransfer(msg.sender, to_, amount_, address(0));
        _isKYCed(msg.sender, to_, amount_, address(0));

        super.transfer(to_, amount_);

        _transferred(msg.sender, to_, amount_, address(0));

        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override(ERC20Upgradeable, IERC20) returns (bool) {
        _canTransfer(from_, to_, amount_, msg.sender);
        _isKYCed(from_, to_, amount_, msg.sender);

        super.transferFrom(from_, to_, amount_);

        _transferred(from_, to_, amount_, msg.sender);

        return true;
    }

    /// @inheritdoc ITokenF
    function mint(
        address account_,
        uint256 amount_
    ) public virtual override onlyRole(_mintRole()) returns (bool) {
        _canTransfer(address(0), account_, amount_, msg.sender);
        _isKYCed(address(0), account_, amount_, msg.sender);

        super._mint(account_, amount_);

        _transferred(address(0), account_, amount_, msg.sender);

        return true;
    }

    /// @inheritdoc ITokenF
    function burn(
        address account_,
        uint256 amount_
    ) public virtual override onlyRole(_burnRole()) returns (bool) {
        _canTransfer(account_, address(0), amount_, msg.sender);
        _isKYCed(account_, address(0), amount_, msg.sender);

        super._burn(account_, amount_);

        _transferred(account_, address(0), amount_, msg.sender);

        return true;
    }

    /// @inheritdoc ITokenF
    function forcedTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override onlyRole(_forcedTransferRole()) returns (bool) {
        _canTransfer(from_, to_, amount_, msg.sender);
        _isKYCed(from_, to_, amount_, msg.sender);

        super._transfer(from_, to_, amount_);

        _transferred(from_, to_, amount_, msg.sender);

        return true;
    }

    /// @inheritdoc IAssetF
    function recovery(
        address oldAccount_,
        address newAccount_
    ) public virtual override onlyRole(_recoveryRole()) returns (bool) {
        uint256 oldBalance_ = balanceOf(oldAccount_);

        _canTransfer(oldAccount_, newAccount_, oldBalance_, msg.sender);
        _isKYCed(oldAccount_, newAccount_, oldBalance_, msg.sender);

        super._transfer(oldAccount_, newAccount_, oldBalance_);

        _transferred(oldAccount_, newAccount_, oldBalance_, msg.sender);

        return true;
    }

    function _transferred(
        address from_,
        address to_,
        uint256 amount_,
        address operator_
    ) internal virtual {
        try
            IRegulatoryCompliance(address(this)).transferred(
                Context(bytes4(bytes(msg.data[:4])), from_, to_, amount_, 0, operator_, "")
            )
        {} catch {
            revert TransferredReverted();
        }
    }

    function _canTransfer(
        address from_,
        address to_,
        uint256 amount_,
        address operator_
    ) internal view virtual {
        try
            IRegulatoryCompliance(address(this)).canTransfer(
                Context(bytes4(bytes(msg.data[:4])), from_, to_, amount_, 0, operator_, "")
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
        uint256 amount_,
        address operator_
    ) internal view virtual {
        try
            IKYCCompliance(address(this)).isKYCed(
                Context(bytes4(bytes(msg.data[:4])), from_, to_, amount_, 0, operator_, "")
            )
        returns (bool isKYCed_) {
            require(isKYCed_, NotKYCed());
        } catch {
            revert IsKYCedReverted();
        }
    }
}
