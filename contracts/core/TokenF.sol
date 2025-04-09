// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {Diamond} from "@solarity/solidity-lib/diamond/Diamond.sol";

import {ITokenF} from "../interfaces/ITokenF.sol";
import {IKYCCompliance} from "../interfaces/IKYCCompliance.sol";
import {IRegulatoryCompliance} from "../interfaces/IRegulatoryCompliance.sol";

import {AgentAccessControl} from "./AgentAccessControl.sol";
import {TokenFStorage} from "./storages/TokenFStorage.sol";
import {RegulatoryComplianceStorage} from "./storages/RegulatoryComplianceStorage.sol";
import {KYCComplianceStorage} from "./storages/KYCComplianceStorage.sol";

abstract contract TokenF is ITokenF, TokenFStorage, Diamond, ERC20Upgradeable, AgentAccessControl {
    bytes4 public constant TRANSFER_SELECTOR = this.transfer.selector;
    bytes4 public constant TRANSFER_FROM_SELECTOR = this.transferFrom.selector;
    bytes4 public constant MINT_SELECTOR = this.mint.selector;
    bytes4 public constant BURN_SELECTOR = this.burn.selector;
    bytes4 public constant FORCED_TRANSFER_SELECTOR = this.forcedTransfer.selector;
    bytes4 public constant RECOVERY_SELECTOR = this.recovery.selector;

    function __TokenF_init(
        address regulatoryCompliance_,
        address kycCompliance_,
        bytes memory initRegulatory_,
        bytes memory initKYC_
    ) internal virtual onlyInitializing {
        bytes4[] memory rComplianceSelectors_ = new bytes4[](6);
        rComplianceSelectors_[0] = IRegulatoryCompliance.addRegulatoryModules.selector;
        rComplianceSelectors_[1] = IRegulatoryCompliance.removeRegulatoryModules.selector;
        rComplianceSelectors_[2] = IRegulatoryCompliance.transferred.selector;
        rComplianceSelectors_[3] = IRegulatoryCompliance.canTransfer.selector;
        rComplianceSelectors_[4] = RegulatoryComplianceStorage.getRegulatoryModules.selector;
        rComplianceSelectors_[5] = RegulatoryComplianceStorage.getRegulatoryModulesCount.selector;

        bytes4[] memory kycComplianceSelectors_ = new bytes4[](5);
        kycComplianceSelectors_[0] = IKYCCompliance.addKYCModules.selector;
        kycComplianceSelectors_[1] = IKYCCompliance.removeKYCModules.selector;
        kycComplianceSelectors_[2] = IKYCCompliance.isKYCed.selector;
        kycComplianceSelectors_[3] = KYCComplianceStorage.getKYCModules.selector;
        kycComplianceSelectors_[4] = KYCComplianceStorage.getKYCModulesCount.selector;

        Facet[] memory facets_ = new Facet[](2);
        facets_[0] = Facet(regulatoryCompliance_, FacetAction.Add, rComplianceSelectors_);
        facets_[1] = Facet(kycCompliance_, FacetAction.Add, kycComplianceSelectors_);

        _diamondCut(facets_, address(0), "");
        _diamondCut(new Facet[](0), regulatoryCompliance_, initRegulatory_);
        _diamondCut(new Facet[](0), kycCompliance_, initKYC_);
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

    /// @inheritdoc ITokenF
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

    /// @inheritdoc ITokenF
    function diamondCut(
        Facet[] memory modules_
    ) public virtual override onlyRole(_diamondCutRole()) {
        diamondCut(modules_, address(0), "");
    }

    /// @inheritdoc ITokenF
    function diamondCut(
        Facet[] memory modules_,
        address initModule_,
        bytes memory initData_
    ) public virtual override onlyRole(_diamondCutRole()) {
        _diamondCut(modules_, initModule_, initData_);
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

    function _mintRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }

    function _burnRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }

    function _forcedTransferRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }

    function _recoveryRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }

    function _diamondCutRole() internal view virtual returns (bytes32) {
        return AGENT_ROLE;
    }
}
