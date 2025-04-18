// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC4906} from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import {IAssetF} from "./IAssetF.sol";

/**
 * @notice The `NFTF` contract
 *
 * The `NFTF` is a Diamond-based ERC721 token implementation enabling the storage of all core contracts under the same Diamond proxy.
 *
 * The `NFTF` provides flexibility for implementing eligibility checks through the integration of compliance modules without
 * affecting the standard ERC721 behaviour.
 *
 * Transfer methods forward the entire transfer context to compliance modules, ensuring adherence to specific requirements,
 * such as regulatory standards or KYC protocols.
 *
 * `NFTF` is also inherited from `AgentAccessControl`, which is built on OpenZeppelin's `AccessControlUpgradeable`.
 * This inheritance allows to realise a rather flexible system of roles for controlling privileged functions in the whole system.
 *
 * Inheritance from `ERC721EnumerableUpgradeable` allows checking all tokens owned by a specific address.
 */
interface INFTF is IAssetF, IERC721Metadata, IERC4906 {
    /**
     * @notice Function for transfering `NFTF` token from the message sender to another address.
     *
     * The `isKYCed` hook from the `KYCCompliance` contract is used inside the function to check KYC.
     * The `canTransfer` and `transferred` hooks are used to check the established regulatory rules
     * from `RegulatoryCompliance` contract.
     *
     *
     * @param to_ The user address to whom token will be transferred
     * @param tokenId_ The ID of the token to be transferred
     */
    function transfer(address to_, uint256 tokenId_) external;

    /**
     * @notice Function to create new `NFTF` contract token.
     *
     * The `isKYCed` hook from the `KYCCompliance` contract is used inside the function to check KYC.
     * The `canTransfer` and `transferred` hooks are used to check the established regulatory rules
     * from `RegulatoryCompliance` contract
     *
     * This function can only be called by users who have a special role.
     * In the base version of `NFTF` this role is the Agent role.
     *
     * To change the role used for access validation,
     * you need to override `_mintRole` according to the requirements of your business task.
     *
     * @param account_ The address to which tokens should be minted
     * @param tokenId_ The ID of the token to be minted
     * @param tokenURI_ The token URI of the token to be minted
     */
    function mint(address account_, uint256 tokenId_, string memory tokenURI_) external;

    /**
     * @notice Function to burn existing `NFTF` contract token.
     *
     * The `isKYCed` hook from the `KYCCompliance` contract is used within the function to check KYC.
     * The `canTransfer` and `transferred` hooks are used to check the established regulatory rules
     * from the `RegulatoryCompliance` contract.
     *
     * This function can only be called by users who have a special role.
     * In the base version of `NFTF` this role is the Agent role.
     *
     * To change the role used for access verification,
     * you must override `_burnRole` according to the requirements of your business task.
     *
     * @param tokenId_ The ID of the token to be burned
     */
    function burn(uint256 tokenId_) external;

    /**
     * @notice Function for forced transfering from one address to another.
     *
     * This logic may be needed for smart contracts that will operate with `NFTF` tokens.
     * It will be convenient because users will not need to call `approve` function additionally.
     *
     * The `isKYCed` hook from the `KYCCompliance` contract is used inside the function to check KYC.
     * The `canTransfer` and `transferred` hooks are used to check the established regulatory rules
     * from `RegulatoryCompliance` contract.
     *
     * This function can only be called by users who have a special role.
     * In the base version of `NFTF` this role is the Agent role.
     *
     * To change the role used for access verification,
     * you must override `_forcedTransferRole` according to the requirements of your business task.
     *
     * @param from_ The user address where the token will be transferred from
     * @param to_ The user address to whom token will be transferred
     * @param tokenId_ The ID of the token to be transferred
     */
    function forcedTransfer(address from_, address to_, uint256 tokenId_) external;

    /**
     * @notice Function to set the base URI for the token metadata.
     * @param baseURI_ The new base URI for the token metadata
     */
    function setBaseURI(string memory baseURI_) external;

    /**
     * @notice Function to set the token URI for an existing token.
     * @param tokenId_ The ID of the token to update
     * @param tokenURI_ The new URI for the token metadata
     */
    function setTokenURI(uint256 tokenId_, string memory tokenURI_) external;
}
