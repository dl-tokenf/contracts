import { ethers } from "hardhat";
import { ZERO_BYTES32 } from "@/scripts/utils/constants";

export const ADMIN_ROLE = ZERO_BYTES32;
export const AGENT_ROLE = ethers.solidityPackedKeccak256(["string"], ["AGENT_ROLE"]);
export const MINT_ROLE = ethers.solidityPackedKeccak256(["string"], ["MINT_ROLE"]);
export const BURN_ROLE = ethers.solidityPackedKeccak256(["string"], ["BURN_ROLE"]);
export const FORCED_TRANSFER_ROLE = ethers.solidityPackedKeccak256(["string"], ["FORCED_TRANSFER_ROLE"]);
export const RECOVERY_ROLE = ethers.solidityPackedKeccak256(["string"], ["RECOVERY_ROLE"]);
export const DIAMOND_CUT_ROLE = ethers.solidityPackedKeccak256(["string"], ["DIAMOND_CUT_ROLE"]);
export const REGULATORY_COMPLIANCE_ROLE = ethers.solidityPackedKeccak256(["string"], ["REGULATORY_COMPLIANCE_ROLE"]);
export const KYC_COMPLIANCE_ROLE = ethers.solidityPackedKeccak256(["string"], ["KYC_COMPLIANCE_ROLE"]);

export enum FacetAction {
  Add,
  Replace,
  Remove,
}

export enum TransferParty {
  Sender,
  Recipient,
  Operator,
}
