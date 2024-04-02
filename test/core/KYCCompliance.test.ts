import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { KYCComplianceMock, KYCFalseModuleMock, KYCTrueModuleMock, TokenFMock } from "@ethers-v6";
import { ZERO_ADDR } from "@/scripts/utils/constants";
import { AGENT_ROLE, DIAMOND_CUT_ROLE, hasRoleErrorMessage, KYC_COMPLIANCE_ROLE } from "@/test/helpers/utils";

describe("KYCCompliance", () => {
  const reverter = new Reverter();

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;

  let tokenF: TokenFMock;
  let kycCompliance: KYCComplianceMock;
  let kycComplianceProxy: KYCComplianceMock;

  let kycTrue: KYCTrueModuleMock;
  let kycFalse: KYCFalseModuleMock;

  before("setup", async () => {
    [owner, agent] = await ethers.getSigners();

    const TokenFMock = await ethers.getContractFactory("TokenFMock");
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    const RegulatoryComplianceMock = await ethers.getContractFactory("RegulatoryComplianceMock");

    const KYCTrueModuleMock = await ethers.getContractFactory("KYCTrueModuleMock");
    const KYCFalseModuleMock = await ethers.getContractFactory("KYCFalseModuleMock");

    kycTrue = await KYCTrueModuleMock.deploy();
    kycFalse = await KYCFalseModuleMock.deploy();

    tokenF = await TokenFMock.deploy();
    kycCompliance = await KYCComplianceMock.deploy();
    const rCompliance = await RegulatoryComplianceMock.deploy();

    const initRegulatory = rCompliance.interface.encodeFunctionData("__RegulatoryComplianceMock_init");
    const initKYC = kycCompliance.interface.encodeFunctionData("__KYCComplianceMock_init");

    await tokenF.__TokenFMock_init("TokenF", "TF", rCompliance, kycCompliance, initRegulatory, initKYC);

    kycComplianceProxy = KYCComplianceMock.attach(tokenF) as KYCComplianceMock;

    await kycComplianceProxy.grantRole(DIAMOND_CUT_ROLE, agent);
    await kycComplianceProxy.grantRole(KYC_COMPLIANCE_ROLE, agent);

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
          ]([], kycCompliance, kycCompliance.interface.encodeFunctionData("__KYCComplianceMock_init")),
      ).to.be.revertedWith("Initializable: contract is already initialized");
    });

    it("should initialize only by top level contract", async () => {
      await expect(
        tokenF
          .connect(agent)
          [
            "diamondCut((address,uint8,bytes4[])[],address,bytes)"
          ]([], kycCompliance, kycCompliance.interface.encodeFunctionData("__KYCComplianceDirect_init")),
      ).to.be.revertedWith("Initializable: contract is not initializing");
    });
  });

  describe("getters", () => {
    it("should return base data", async () => {
      expect(await kycCompliance.defaultKYCComplianceRole()).to.eq(AGENT_ROLE);
    });
  });

  describe("addKYCModules", () => {
    it("should not add KYC modules if no role", async () => {
      await kycComplianceProxy.revokeRole(KYC_COMPLIANCE_ROLE, agent);

      await expect(kycComplianceProxy.connect(agent).addKYCModules([kycTrue])).to.be.revertedWith(
        await hasRoleErrorMessage(agent, KYC_COMPLIANCE_ROLE),
      );
    });

    it("should not add KYC modules if duplicates", async () => {
      await expect(kycComplianceProxy.connect(agent).addKYCModules([kycTrue, kycTrue])).to.be.revertedWith(
        "SetHelper: element already exists",
      );
    });

    it("should add KYC modules if all conditions are met", async () => {
      await kycComplianceProxy.connect(agent).addKYCModules([kycTrue]);

      expect(await kycComplianceProxy.getKYCModules()).to.deep.eq([await kycTrue.getAddress()]);
    });
  });

  describe("removeKYCModules", () => {
    it("should not remove KYC modules if no role", async () => {
      await kycComplianceProxy.revokeRole(KYC_COMPLIANCE_ROLE, agent);

      await expect(kycComplianceProxy.connect(agent).removeKYCModules([kycTrue])).to.be.revertedWith(
        await hasRoleErrorMessage(agent, KYC_COMPLIANCE_ROLE),
      );
    });

    it("should not remove KYC modules if no module", async () => {
      await expect(kycComplianceProxy.connect(agent).removeKYCModules([kycTrue])).to.be.revertedWith(
        "SetHelper: no such element",
      );
    });

    it("should remove KYC modules if all conditions are met", async () => {
      await kycComplianceProxy.connect(agent).addKYCModules([kycTrue]);
      await kycComplianceProxy.connect(agent).removeKYCModules([kycTrue]);

      expect(await kycComplianceProxy.getKYCModules()).to.deep.eq([]);
    });
  });

  describe("isKYCed", () => {
    it("should not be KYCed if modules return false", async () => {
      await kycComplianceProxy.connect(agent).addKYCModules([kycTrue, kycFalse]);

      expect(
        await kycComplianceProxy.isKYCed({
          selector: "0x00000000",
          from: ZERO_ADDR,
          to: ZERO_ADDR,
          amount: 0,
          operator: ZERO_ADDR,
          data: "0x",
        }),
      ).to.be.false;
    });

    it("should be KYCed if modules return true", async () => {
      await kycComplianceProxy.connect(agent).addKYCModules([kycTrue]);

      expect(
        await kycComplianceProxy.isKYCed({
          selector: "0x00000000",
          from: ZERO_ADDR,
          to: ZERO_ADDR,
          amount: 0,
          operator: ZERO_ADDR,
          data: "0x",
        }),
      ).to.be.true;
    });
  });
});
