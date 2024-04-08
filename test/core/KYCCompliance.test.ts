import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { KYCComplianceMock, KYCIncorrectModuleMock, KYCCorrectModuleMock, TokenFMock } from "@ethers-v6";
import { ZERO_ADDR, ZERO_SELECTOR } from "@/scripts/utils/constants";
import { AGENT_ROLE, DIAMOND_CUT_ROLE, hasRoleErrorMessage, KYC_COMPLIANCE_ROLE } from "@/test/helpers/utils";

describe("KYCCompliance", () => {
  const reverter = new Reverter();

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;

  let tokenF: TokenFMock;
  let kycCompliance: KYCComplianceMock;
  let kycComplianceProxy: KYCComplianceMock;

  let kycCorrect: KYCCorrectModuleMock;
  let kycIncorrect: KYCIncorrectModuleMock;

  before("setup", async () => {
    [owner, agent] = await ethers.getSigners();

    const TokenFMock = await ethers.getContractFactory("TokenFMock");
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    const RegulatoryComplianceMock = await ethers.getContractFactory("RegulatoryComplianceMock");

    const KYCCorrectModuleMock = await ethers.getContractFactory("KYCCorrectModuleMock");
    const KYCIncorrectModuleMock = await ethers.getContractFactory("KYCIncorrectModuleMock");

    kycCorrect = await KYCCorrectModuleMock.deploy();
    kycIncorrect = await KYCIncorrectModuleMock.deploy();

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

      await expect(kycComplianceProxy.connect(agent).addKYCModules([kycCorrect])).to.be.revertedWith(
        await hasRoleErrorMessage(agent, KYC_COMPLIANCE_ROLE),
      );
    });

    it("should not add KYC modules if duplicates", async () => {
      await expect(kycComplianceProxy.connect(agent).addKYCModules([kycCorrect, kycCorrect])).to.be.revertedWith(
        "SetHelper: element already exists",
      );
    });

    it("should add KYC modules if all conditions are met", async () => {
      await kycComplianceProxy.connect(agent).addKYCModules([kycCorrect]);

      expect(await kycComplianceProxy.getKYCModulesCount()).to.eq(1);
      expect(await kycComplianceProxy.getKYCModules()).to.deep.eq([await kycCorrect.getAddress()]);
    });
  });

  describe("removeKYCModules", () => {
    it("should not remove KYC modules if no role", async () => {
      await kycComplianceProxy.revokeRole(KYC_COMPLIANCE_ROLE, agent);

      await expect(kycComplianceProxy.connect(agent).removeKYCModules([kycCorrect])).to.be.revertedWith(
        await hasRoleErrorMessage(agent, KYC_COMPLIANCE_ROLE),
      );
    });

    it("should not remove KYC modules if no module", async () => {
      await expect(kycComplianceProxy.connect(agent).removeKYCModules([kycCorrect])).to.be.revertedWith(
        "SetHelper: no such element",
      );
    });

    it("should remove KYC modules if all conditions are met", async () => {
      await kycComplianceProxy.connect(agent).addKYCModules([kycCorrect]);
      await kycComplianceProxy.connect(agent).removeKYCModules([kycCorrect]);

      expect(await kycComplianceProxy.getKYCModulesCount()).to.eq(0);
      expect(await kycComplianceProxy.getKYCModules()).to.deep.eq([]);
    });
  });

  describe("isKYCed", () => {
    it("should not be KYCed if modules return Incorrect", async () => {
      await kycComplianceProxy.connect(agent).addKYCModules([kycCorrect, kycIncorrect]);

      expect(
        await kycComplianceProxy.isKYCed({
          selector: ZERO_SELECTOR,
          from: ZERO_ADDR,
          to: ZERO_ADDR,
          amount: 0,
          operator: ZERO_ADDR,
          data: "0x",
        }),
      ).to.be.false;
    });

    it("should be KYCed if modules return Correct", async () => {
      await kycComplianceProxy.connect(agent).addKYCModules([kycCorrect]);

      expect(
        await kycComplianceProxy.isKYCed({
          selector: ZERO_SELECTOR,
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
