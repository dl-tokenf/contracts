// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Diamond} from "@solarity/solidity-lib/diamond/Diamond.sol";

interface ITokenF is IERC20Metadata {
    function mint(address account_, uint256 amount_) external returns (bool);

    function burn(address account_, uint256 amount_) external returns (bool);

    function forcedTransfer(address from_, address to_, uint256 amount_) external returns (bool);

    function recovery(address oldAccount_, address newAccount_) external returns (bool);

    function diamondCut(Diamond.Facet[] memory modules_) external;

    function diamondCut(
        Diamond.Facet[] memory modules_,
        address initModule_,
        bytes memory initData_
    ) external;
}
