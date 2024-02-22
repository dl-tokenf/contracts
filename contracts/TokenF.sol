// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Diamond} from "@solarity/solidity-lib/diamond/Diamond.sol";
import {DiamondERC20} from "@solarity/solidity-lib/diamond/tokens/ERC20/DiamondERC20.sol";

import {RegulatoryCompliance} from "./regulatory/RegulatoryCompliance.sol";

abstract contract TokenF is Diamond, DiamondERC20 {
    modifier onlyPermission() {
        _;
    }

    function transfer(address to_, uint256 amount_) public virtual override returns (bool) {
        _canTransfer(msg.sender, to_, amount_, address(0));

        super.transfer(to_, amount_);

        _transferred(msg.sender, to_, amount_, address(0));

        return true;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override returns (bool) {
        _canTransfer(msg.sender, to_, amount_, address(0));

        super.transferFrom(from_, to_, amount_);

        _transferred(msg.sender, to_, amount_, address(0));

        return true;
    }

    function mint(address account_, uint256 amount_) public virtual onlyPermission {
        _canTransfer(address(0), account_, amount_, msg.sender);

        _mint(account_, amount_);

        _transferred(address(0), account_, amount_, msg.sender);
    }

    function burn(address account_, uint256 amount_) public virtual onlyPermission {
        _canTransfer(account_, address(0), amount_, msg.sender);

        _burn(account_, amount_);

        _transferred(account_, address(0), amount_, msg.sender);
    }

    function forcedTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual onlyPermission {
        _canTransfer(from_, to_, amount_, msg.sender);

        _transfer(from_, to_, amount_);

        _transferred(from_, to_, amount_, msg.sender);
    }

    function recovery(address oldAccount_, address newAccount_) public virtual onlyPermission {
        uint256 oldBalance_ = balanceOf(oldAccount_);

        _canTransfer(oldAccount_, newAccount_, oldBalance_, msg.sender);

        _transfer(oldAccount_, newAccount_, oldBalance_);

        _transferred(oldAccount_, newAccount_, oldBalance_, msg.sender);
    }

    function diamondCut(Facet[] memory modules_) public virtual onlyPermission {
        diamondCut(modules_, address(0), "");
    }

    function diamondCut(
        Facet[] memory modules_,
        address initModule_,
        bytes memory initData_
    ) public virtual onlyPermission {
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
                operator_
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
    ) internal virtual {
        try
            RegulatoryCompliance(address(this)).canTransfer(
                bytes4(bytes(msg.data[:4])),
                from_,
                to_,
                amount_,
                operator_
            )
        returns (bool canTransfer_) {
            require(canTransfer_, "TokenF: cannot transfer");
        } catch {
            revert("TokenF: canTransfer reverted");
        }
    }
}
