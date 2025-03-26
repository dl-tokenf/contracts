import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { TokenFMock, AgentAccessControlMock } from "@ethers-v6";
import { ADMIN_ROLE, AGENT_ROLE, DIAMOND_CUT_ROLE } from "@/test/helpers/utils";

describe("AgentAccessControl", () => {
  const reverter = new Reverter();

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;

  let tokenF: TokenFMock;
  let accessControl: AgentAccessControlMock;
  let accessControlProxy: AgentAccessControlMock;

  before("setup", async () => {
    [owner, agent] = await ethers.getSigners();

    const TokenFMock = await ethers.getContractFactory("TokenFMock");
    const AgentAccessControlMock = await ethers.getContractFactory("AgentAccessControlMock");
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    const RegulatoryComplianceMock = await ethers.getContractFactory("RegulatoryComplianceMock");

    tokenF = await TokenFMock.deploy();
    const kycCompliance = await KYCComplianceMock.deploy();
    const rCompliance = await RegulatoryComplianceMock.deploy();

    const initRegulatory = rCompliance.interface.encodeFunctionData("__RegulatoryComplianceDirect_init");
    const initKYC = kycCompliance.interface.encodeFunctionData("__KYCComplianceDirect_init");

    await tokenF.__TokenFMock_init("TokenF", "TF", rCompliance, kycCompliance, initRegulatory, initKYC);

    accessControl = await AgentAccessControlMock.deploy();
    accessControlProxy = AgentAccessControlMock.attach(tokenF) as AgentAccessControlMock;

    await tokenF.grantRole(DIAMOND_CUT_ROLE, agent);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(
        tokenF
          .connect(agent)
          [
            "diamondCut((address,uint8,bytes4[])[],address,bytes)"
          ]([], accessControl, accessControl.interface.encodeFunctionData("__AgentAccessControlMock_init")),
      ).to.be.revertedWithCustomError(accessControl, "InvalidInitialization");
    });

    it("should initialize only by top level contract", async () => {
      await expect(
        tokenF
          .connect(agent)
          [
            "diamondCut((address,uint8,bytes4[])[],address,bytes)"
          ]([], accessControl, accessControl.interface.encodeFunctionData("__AgentAccessControlDirect_init")),
      ).to.be.revertedWithCustomError(accessControl, "NotInitializing");
    });
  });

  describe("checkRole", () => {
    it("should revert if no role", async () => {
      await expect(accessControlProxy.checkRole(AGENT_ROLE, agent))
        .to.be.revertedWithCustomError(accessControl, "AccessControlUnauthorizedAccount")
        .withArgs(agent, AGENT_ROLE);
    });

    it("should not revert if has role", async () => {
      await accessControlProxy.grantRole(AGENT_ROLE, agent);

      await expect(accessControlProxy.checkRole(AGENT_ROLE, agent)).to.not.be.reverted;
      await expect(accessControlProxy.checkRole(ADMIN_ROLE, owner)).to.not.be.reverted;
    });
  });
});
