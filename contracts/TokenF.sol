// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Diamond} from "@solarity/solidity-lib/diamond/Diamond.sol";
import {DiamondERC20} from "@solarity/solidity-lib/diamond/tokens/ERC20/DiamondERC20.sol";

import {AgentAccessControl} from "./access/AgentAccessControl.sol";
import {RegulatoryCompliance} from "./regulatory/RegulatoryCompliance.sol";
import {KYCCompliance} from "./kyc/KYCCompliance.sol";

abstract contract TokenF is Diamond, DiamondERC20, AgentAccessControl {
    bytes4 public constant TRANSFER_SELECTOR = this.transfer.selector;
    bytes4 public constant TRANSFER_FROM_SELECTOR = this.transferFrom.selector;
    bytes4 public constant MINT_SELECTOR = this.mint.selector;
    bytes4 public constant BURN_SELECTOR = this.burn.selector;
    bytes4 public constant FORCED_TRANSFER_SELECTOR = this.forcedTransfer.selector;
    bytes4 public constant RECOVERY_SELECTOR = this.recovery.selector;

    uint8 public constant TRANSFER_SENDER = 1;
    uint8 public constant TRANSFER_RECIPIENT = 2;
    uint8 public constant TRANSFER_OPERATOR = 3;

    function transfer(address to_, uint256 amount_) public virtual override returns (bool) {
        _canTransfer(msg.sender, to_, amount_, address(0));
        _isKYCed(msg.sender, to_, amount_, address(0));

        super.transfer(to_, amount_);

        _transferred(msg.sender, to_, amount_, address(0));

        return true;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override returns (bool) {
        _canTransfer(from_, to_, amount_, address(0));
        _isKYCed(from_, to_, amount_, address(0));

        super.transferFrom(from_, to_, amount_);

        _transferred(from_, to_, amount_, address(0));

        return true;
    }

    function mint(address account_, uint256 amount_) public virtual onlyRole(_mintRole()) {
        _canTransfer(address(0), account_, amount_, msg.sender);
        _isKYCed(address(0), account_, amount_, msg.sender);

        super._mint(account_, amount_);

        _transferred(address(0), account_, amount_, msg.sender);
    }

    function burn(address account_, uint256 amount_) public virtual onlyRole(_burnRole()) {
        _canTransfer(account_, address(0), amount_, msg.sender);
        _isKYCed(account_, address(0), amount_, msg.sender);

        super._burn(account_, amount_);

        _transferred(account_, address(0), amount_, msg.sender);
    }

    function forcedTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual onlyRole(_forcedTransferRole()) {
        _canTransfer(from_, to_, amount_, msg.sender);
        _isKYCed(from_, to_, amount_, msg.sender);

        super._transfer(from_, to_, amount_);

        _transferred(from_, to_, amount_, msg.sender);
    }

    function recovery(
        address oldAccount_,
        address newAccount_
    ) public virtual onlyRole(_recoveryRole()) {
        uint256 oldBalance_ = balanceOf(oldAccount_);

        _canTransfer(oldAccount_, newAccount_, oldBalance_, msg.sender);
        _isKYCed(oldAccount_, newAccount_, oldBalance_, msg.sender);

        super._transfer(oldAccount_, newAccount_, oldBalance_);

        _transferred(oldAccount_, newAccount_, oldBalance_, msg.sender);
    }

    function diamondCut(Facet[] memory modules_) public virtual onlyRole(_diamondCutRole()) {
        diamondCut(modules_, address(0), "");
    }

    function diamondCut(
        Facet[] memory modules_,
        address initModule_,
        bytes memory initData_
    ) public virtual onlyRole(_diamondCutRole()) {
        _diamondCut(modules_, initModule_, initData_);
    }

    function _transferred(
        address from_,
        address to_,
        uint256 amount_,
        address operator_
    ) internal virtual {
        try
            RegulatoryCompliance(address(this)).transferred(
                bytes4(bytes(msg.data[:4])),
                from_,
                to_,
                amount_,
                operator_,
                ""
            )
        {} catch {
            revert("TokenF: transferred reverted");
        }
    }

    function _canTransfer(
        address from_,
        address to_,
        uint256 amount_,
        address operator_
    ) internal view virtual {
        try
            RegulatoryCompliance(address(this)).canTransfer(
                bytes4(bytes(msg.data[:4])),
                from_,
                to_,
                amount_,
                operator_,
                ""
            )
        returns (bool canTransfer_) {
            require(canTransfer_, "TokenF: cannot transfer");
        } catch {
            revert("TokenF: canTransfer reverted");
        }
    }

    function _isKYCed(
        address from_,
        address to_,
        uint256 amount_,
        address operator_
    ) internal view virtual {
        try
            KYCCompliance(address(this)).isKYCed(
                bytes4(bytes(msg.data[:4])),
                from_,
                to_,
                amount_,
                operator_,
                ""
            )
        returns (bool isKYCed_) {
            require(isKYCed_, "TokenF: not KYCed");
        } catch {
            revert("TokenF: isKYCed reverted");
        }
    }

    function _mintRole() internal view virtual returns (bytes32) {
        return getAgentRole();
    }

    function _burnRole() internal view virtual returns (bytes32) {
        return getAgentRole();
    }

    function _forcedTransferRole() internal view virtual returns (bytes32) {
        return getAgentRole();
    }

    function _recoveryRole() internal view virtual returns (bytes32) {
        return getAgentRole();
    }

    function _diamondCutRole() internal view virtual returns (bytes32) {
        return getAgentRole();
    }
}
