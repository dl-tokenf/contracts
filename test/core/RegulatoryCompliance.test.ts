import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import {
  RegulatoryComplianceMock,
  RegulatoryIncorrectModuleMock,
  RegulatoryCorrectModuleMock,
  TokenFMock,
} from "@ethers-v6";
import { ZERO_ADDR, ZERO_SELECTOR } from "@/scripts/utils/constants";
import { AGENT_ROLE, DIAMOND_CUT_ROLE, MINT_ROLE, REGULATORY_COMPLIANCE_ROLE } from "@/test/helpers/utils";
import { wei } from "@/scripts/utils/utils";

describe("RegulatoryCompliance", () => {
  const reverter = new Reverter();

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;

  let tokenF: TokenFMock;
  let rCompliance: RegulatoryComplianceMock;
  let rComplianceProxy: RegulatoryComplianceMock;

  let rCorrect: RegulatoryCorrectModuleMock;
  let rIncorrect: RegulatoryIncorrectModuleMock;

  before("setup", async () => {
    [owner, agent] = await ethers.getSigners();

    const TokenFMock = await ethers.getContractFactory("TokenFMock");
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    const RegulatoryComplianceMock = await ethers.getContractFactory("RegulatoryComplianceMock");

    const RegulatoryCorrectModuleMock = await ethers.getContractFactory("RegulatoryCorrectModuleMock");
    const RegulatoryIncorrectModuleMock = await ethers.getContractFactory("RegulatoryIncorrectModuleMock");

    tokenF = await TokenFMock.deploy();
    rCompliance = await RegulatoryComplianceMock.deploy();
    const kycCompliance = await KYCComplianceMock.deploy();

    const initRegulatory = rCompliance.interface.encodeFunctionData("__RegulatoryComplianceDirect_init");
    const initKYC = kycCompliance.interface.encodeFunctionData("__KYCComplianceDirect_init");

    await tokenF.__TokenFMock_init("TokenF", "TF", rCompliance, kycCompliance, initRegulatory, initKYC);

    rComplianceProxy = RegulatoryComplianceMock.attach(tokenF) as RegulatoryComplianceMock;

    await rComplianceProxy.grantRole(MINT_ROLE, agent);
    await rComplianceProxy.grantRole(DIAMOND_CUT_ROLE, agent);
    await rComplianceProxy.grantRole(REGULATORY_COMPLIANCE_ROLE, agent);

    rCorrect = await RegulatoryCorrectModuleMock.deploy();
    rIncorrect = await RegulatoryIncorrectModuleMock.deploy();

    await rCorrect.__RegulatoryCorrectModuleMock_init(tokenF);
    await rIncorrect.__RegulatoryIncorrectModuleMock_init(tokenF);

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
          ]([], rCompliance, rCompliance.interface.encodeFunctionData("__RegulatoryComplianceMock_init")),
      ).to.be.revertedWithCustomError(rCompliance, "InvalidInitialization");
    });

    it("should initialize only by top level contract", async () => {
      await expect(
        tokenF
          .connect(agent)
          [
            "diamondCut((address,uint8,bytes4[])[],address,bytes)"
          ]([], rCompliance, rCompliance.interface.encodeFunctionData("__RegulatoryComplianceDirect_init")),
      ).to.be.revertedWithCustomError(rCompliance, "NotInitializing");
    });
  });

  describe("getters", () => {
    it("should return base data", async () => {
      expect(await rCompliance.defaultRegulatoryComplianceRole()).to.eq(AGENT_ROLE);
    });
  });

  describe("addRegulatoryModules", () => {
    it("should not add regulatory modules if no role", async () => {
      await rComplianceProxy.revokeRole(REGULATORY_COMPLIANCE_ROLE, agent);

      await expect(rComplianceProxy.connect(agent).addRegulatoryModules([rCorrect]))
        .to.be.revertedWithCustomError(rComplianceProxy, "AccessControlUnauthorizedAccount")
        .withArgs(agent, REGULATORY_COMPLIANCE_ROLE);
    });

    it("should not add regulatory modules if duplicates", async () => {
      await expect(rComplianceProxy.connect(agent).addRegulatoryModules([rCorrect, rCorrect]))
        .to.be.revertedWithCustomError(rComplianceProxy, "ElementAlreadyExistsAddress")
        .withArgs(rCorrect);
    });

    it("should add regulatory modules if all conditions are met", async () => {
      await rComplianceProxy.connect(agent).addRegulatoryModules([rCorrect]);

      expect(await rComplianceProxy.getRegulatoryModulesCount()).to.eq(1);
      expect(await rComplianceProxy.getRegulatoryModules()).to.deep.eq([await rCorrect.getAddress()]);
    });
  });

  describe("removeRegulatoryModules", () => {
    it("should not remove regulatory modules if no role", async () => {
      await rComplianceProxy.revokeRole(REGULATORY_COMPLIANCE_ROLE, agent);

      await expect(rComplianceProxy.connect(agent).removeRegulatoryModules([rCorrect]))
        .to.be.revertedWithCustomError(rComplianceProxy, "AccessControlUnauthorizedAccount")
        .withArgs(agent, REGULATORY_COMPLIANCE_ROLE);
    });

    it("should not remove regulatory modules if no module", async () => {
      await expect(rComplianceProxy.connect(agent).removeRegulatoryModules([rCorrect]))
        .to.be.revertedWithCustomError(rComplianceProxy, "NoSuchAddress")
        .withArgs(rCorrect);
    });

    it("should remove regulatory modules if all conditions are met", async () => {
      await rComplianceProxy.connect(agent).addRegulatoryModules([rCorrect]);
      await rComplianceProxy.connect(agent).removeRegulatoryModules([rCorrect]);

      expect(await rComplianceProxy.getRegulatoryModulesCount()).to.eq(0);
      expect(await rComplianceProxy.getRegulatoryModules()).to.deep.eq([]);
    });
  });

  describe("transferred", () => {
    it("should not transfer if not this", async () => {
      await rComplianceProxy.connect(agent).addRegulatoryModules([rCorrect]);

      await expect(
        rComplianceProxy.transferred({
          selector: ZERO_SELECTOR,
          from: ZERO_ADDR,
          to: ZERO_ADDR,
          amount: 0,
          operator: ZERO_ADDR,
          data: "0x",
        }),
      )
        .to.be.revertedWithCustomError(rComplianceProxy, "SenderIsNotThisContract")
        .withArgs(owner);
    });

    it("should transfer if all conditions are met", async () => {
      await rComplianceProxy.connect(agent).addRegulatoryModules([rCorrect]);

      await expect(tokenF.connect(agent).mint(agent, wei("1"))).to.not.be.reverted;
    });
  });

  describe("canTransfer", () => {
    it("should not transfer if modules return Incorrect", async () => {
      await rComplianceProxy.connect(agent).addRegulatoryModules([rCorrect, rIncorrect]);

      expect(
        await rComplianceProxy.canTransfer({
          selector: ZERO_SELECTOR,
          from: ZERO_ADDR,
          to: ZERO_ADDR,
          amount: 0,
          operator: ZERO_ADDR,
          data: "0x",
        }),
      ).to.be.false;
    });

    it("should transfer if modules return Correct", async () => {
      await rComplianceProxy.connect(agent).addRegulatoryModules([rCorrect]);

      expect(
        await rComplianceProxy.canTransfer({
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
