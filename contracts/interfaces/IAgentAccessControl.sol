// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAccessControl} from "@solarity/solidity-lib/diamond/access/access-control/ADiamondAccessControl.sol";

/**
 * @notice The `AgentAccessControl` contract is an add-on to Solarity's `DiamondAccessControl` and adds one basic role, `AGENT_ROLE`, to its implementation.
 * This role is used in the base version of the `TokenF` framework for all privileged functions such as `mint`, `burn`, `addKYCModules`, etc.
 */
interface IAgentAccessControl is IAccessControl {
    /**
     * @notice Function that returns the key for the base role is `AGENT_ROLE`.
     *
     * All addresses that own this role are privileged and can call various functions to manage parts of the token.
     *
     * In a basic implementation of `TokenF`, a user with the Agent role can call absolutely all the privileged functions, such as `mint`, `burn` and etc.
     *
     * The Agent role key itself is created as follows - `keccak256("AGENT_ROLE")`
     *
     * @return The key for the agent role
     */
    function AGENT_ROLE() external view returns (bytes32);

    /**
     * @notice Function that is required to check whether a particular user has the required role for the contract logic.
     *
     * If the user does not have the required role, the transaction will fail with the error
     * `AccessControl: account *<user-address>* is missing role *<role-key>*`.
     *
     * @param role_ The role key to check
     * @param account_ The account for role verification
     */
    function checkRole(bytes32 role_, address account_) external view;
}
