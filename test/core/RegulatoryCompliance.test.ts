import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { wei } from "@/scripts/utils/utils";
import { Reverter } from "@/test/helpers/reverter";
import { RegulatoryComplianceMock, RegulatoryFalseModuleMock, RegulatoryTrueModuleMock, TokenFMock } from "@ethers-v6";
import { ZERO_ADDR } from "@/scripts/utils/constants";
import { AGENT_ROLE, DIAMOND_CUT_ROLE, hasRoleErrorMessage, REGULATORY_COMPLIANCE_ROLE } from "@/test/helpers/utils";

describe.only("RegulatoryCompliance", () => {
  const reverter = new Reverter();

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;

  let tokenF: TokenFMock;
  let rCompliance: RegulatoryComplianceMock;
  let rComplianceProxy: RegulatoryComplianceMock;

  let rTrue: RegulatoryTrueModuleMock;
  let rFalse: RegulatoryFalseModuleMock;

  before("setup", async () => {
    [owner, agent] = await ethers.getSigners();

    const TokenFMock = await ethers.getContractFactory("TokenFMock");
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    const RegulatoryComplianceMock = await ethers.getContractFactory("RegulatoryComplianceMock");

    const RegulatoryTrueModuleMock = await ethers.getContractFactory("RegulatoryTrueModuleMock");
    const RegulatoryFalseModuleMock = await ethers.getContractFactory("RegulatoryFalseModuleMock");

    rTrue = await RegulatoryTrueModuleMock.deploy();
    rFalse = await RegulatoryFalseModuleMock.deploy();

    tokenF = await TokenFMock.deploy();
    rCompliance = await RegulatoryComplianceMock.deploy();
    const kycCompliance = await KYCComplianceMock.deploy();

    const initRegulatory = rCompliance.interface.encodeFunctionData("__RegulatoryComplianceMock_init");
    const initKYC = kycCompliance.interface.encodeFunctionData("__KYCComplianceMock_init");

    await tokenF.__TokenFMock_init("TokenF", "TF", rCompliance, kycCompliance, initRegulatory, initKYC);

    rComplianceProxy = RegulatoryComplianceMock.attach(tokenF) as RegulatoryComplianceMock;

    await rComplianceProxy.grantRole(DIAMOND_CUT_ROLE, agent);
    await rComplianceProxy.grantRole(REGULATORY_COMPLIANCE_ROLE, agent);

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
      ).to.be.revertedWith("Initializable: contract is already initialized");
    });

    it("should initialize only by top level contract", async () => {
      await expect(
        tokenF
          .connect(agent)
          [
            "diamondCut((address,uint8,bytes4[])[],address,bytes)"
          ]([], rCompliance, rCompliance.interface.encodeFunctionData("__RegulatoryComplianceDirect_init")),
      ).to.be.revertedWith("Initializable: contract is not initializing");
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

      await expect(rComplianceProxy.connect(agent).addRegulatoryModules([rTrue])).to.be.revertedWith(
        await hasRoleErrorMessage(agent, REGULATORY_COMPLIANCE_ROLE),
      );
    });

    it("should not add regulatory modules if duplicates", async () => {
      await expect(rComplianceProxy.connect(agent).addRegulatoryModules([rTrue, rTrue])).to.be.revertedWith(
        "SetHelper: element already exists",
      );
    });

    it("should add regulatory modules if all conditions are met", async () => {
      await rComplianceProxy.connect(agent).addRegulatoryModules([rTrue]);

      expect(await rComplianceProxy.getRegulatoryModules()).to.deep.eq([await rTrue.getAddress()]);
    });
  });

  describe("removeRegulatoryModules", () => {
    it("should not remove regulatory modules if no role", async () => {
      await rComplianceProxy.revokeRole(REGULATORY_COMPLIANCE_ROLE, agent);

      await expect(rComplianceProxy.connect(agent).removeRegulatoryModules([rTrue])).to.be.revertedWith(
        await hasRoleErrorMessage(agent, REGULATORY_COMPLIANCE_ROLE),
      );
    });

    it("should not remove regulatory modules if no module", async () => {
      await expect(rComplianceProxy.connect(agent).removeRegulatoryModules([rTrue])).to.be.revertedWith(
        "SetHelper: no such element",
      );
    });

    it("should remove regulatory modules if all conditions are met", async () => {
      await rComplianceProxy.connect(agent).addRegulatoryModules([rTrue]);
      await rComplianceProxy.connect(agent).removeRegulatoryModules([rTrue]);

      expect(await rComplianceProxy.getRegulatoryModules()).to.deep.eq([]);
    });
  });

  describe("transferred", () => {
    it("should not transfer if not this", async () => {
      await expect(
        rComplianceProxy.transferred({
          selector: "0x00000000",
          from: ZERO_ADDR,
          to: ZERO_ADDR,
          amount: 0,
          operator: ZERO_ADDR,
          data: "0x",
        }),
      ).to.be.revertedWith("RCompliance: not this");
    });
  });

  describe("canTransfer", () => {
    it("should not transfer if modules return false", async () => {
      await rComplianceProxy.connect(agent).addRegulatoryModules([rTrue, rFalse]);

      expect(
        await rComplianceProxy.canTransfer({
          selector: "0x00000000",
          from: ZERO_ADDR,
          to: ZERO_ADDR,
          amount: 0,
          operator: ZERO_ADDR,
          data: "0x",
        }),
      ).to.be.false;
    });

    it("should transfer if modules return true", async () => {
      await rComplianceProxy.connect(agent).addRegulatoryModules([rTrue]);

      expect(
        await rComplianceProxy.canTransfer({
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
