import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { RegulatoryComplianceMock, TokenFMock, ERC20TransferLimitsModuleMock } from "@ethers-v6";
import { ZERO_ADDR } from "@/scripts/utils/constants";
import { AGENT_ROLE, MINT_ROLE, REGULATORY_COMPLIANCE_ROLE } from "@/test/helpers/utils";
import { wei } from "@/scripts/utils/utils";

describe("ERC20TransferLimitsModule", () => {
  const reverter = new Reverter();

  const MIN_TRANSFER_LIMIT = wei("1");
  const MAX_TRANSFER_LIMIT = wei("2");

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;
  let alice: SignerWithAddress;
  let bob: SignerWithAddress;

  let tokenF: TokenFMock;
  let transferLimits: ERC20TransferLimitsModuleMock;

  before("setup", async () => {
    [owner, agent, alice, bob] = await ethers.getSigners();

    const TokenFMock = await ethers.getContractFactory("TokenFMock");
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    const RegulatoryComplianceMock = await ethers.getContractFactory("RegulatoryComplianceMock");
    const ERC20TransferLimitsModuleMock = await ethers.getContractFactory("ERC20TransferLimitsModuleMock");

    tokenF = await TokenFMock.deploy();
    const rCompliance = await RegulatoryComplianceMock.deploy();
    const kycCompliance = await KYCComplianceMock.deploy();

    const initRegulatory = rCompliance.interface.encodeFunctionData("__RegulatoryComplianceDirect_init");
    const initKYC = kycCompliance.interface.encodeFunctionData("__KYCComplianceDirect_init");

    await tokenF.__TokenFMock_init("TokenF", "TF", rCompliance, kycCompliance, initRegulatory, initKYC);

    const rComplianceProxy = RegulatoryComplianceMock.attach(tokenF) as RegulatoryComplianceMock;

    await tokenF.grantRole(AGENT_ROLE, agent);
    await tokenF.grantRole(MINT_ROLE, agent);
    await tokenF.grantRole(REGULATORY_COMPLIANCE_ROLE, agent);

    transferLimits = await ERC20TransferLimitsModuleMock.deploy();
    await transferLimits.__ERC20TransferLimitsModuleMock_init(tokenF, MIN_TRANSFER_LIMIT, MAX_TRANSFER_LIMIT);

    await rComplianceProxy.connect(agent).addRegulatoryModules([transferLimits]);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(transferLimits.__ERC20TransferLimitsModuleMock_init(ZERO_ADDR, 0, 0)).to.be.revertedWithCustomError(
        transferLimits,
        "InvalidInitialization",
      );
    });

    it("should initialize only by top level contract", async () => {
      await expect(transferLimits.__TransferLimitsDirect_init()).to.be.revertedWithCustomError(
        transferLimits,
        "NotInitializing",
      );
    });
  });

  describe("getters", () => {
    it("should return base data", async () => {
      expect(await transferLimits.getTransferLimits()).to.deep.eq([MIN_TRANSFER_LIMIT, MAX_TRANSFER_LIMIT]);
    });
  });

  describe("setMinTransferLimit", () => {
    it("should not set min transfer limit if no role", async () => {
      await tokenF.revokeRole(AGENT_ROLE, agent);

      await expect(transferLimits.connect(agent).setMinTransferLimit(MIN_TRANSFER_LIMIT + 1n))
        .to.be.revertedWithCustomError(tokenF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, AGENT_ROLE);
    });

    it("should set min transfer limit if all conditions are met", async () => {
      await transferLimits.connect(agent).setMinTransferLimit(MIN_TRANSFER_LIMIT + 1n);

      expect(await transferLimits.getTransferLimits()).to.deep.eq([MIN_TRANSFER_LIMIT + 1n, MAX_TRANSFER_LIMIT]);
    });
  });

  describe("setMaxTransferLimit", () => {
    it("should not set max transfer limit if no role", async () => {
      await tokenF.revokeRole(AGENT_ROLE, agent);

      await expect(transferLimits.connect(agent).setMaxTransferLimit(MAX_TRANSFER_LIMIT + 1n))
        .to.be.revertedWithCustomError(tokenF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, AGENT_ROLE);
    });

    it("should set max transfer limit if all conditions are met", async () => {
      await transferLimits.connect(agent).setMaxTransferLimit(MAX_TRANSFER_LIMIT + 1n);

      expect(await transferLimits.getTransferLimits()).to.deep.eq([MIN_TRANSFER_LIMIT, MAX_TRANSFER_LIMIT + 1n]);
    });
  });

  describe("integration", () => {
    let transferKey: string;
    let transferFromKey: string;

    const setupHandlerTopics = async () => {
      await transferLimits.addHandlerTopics(transferKey, [
        await transferLimits.MIN_TRANSFER_LIMIT_TOPIC(),
        await transferLimits.MAX_TRANSFER_LIMIT_TOPIC(),
      ]);
      await transferLimits.addHandlerTopics(transferFromKey, [
        await transferLimits.MIN_TRANSFER_LIMIT_TOPIC(),
        await transferLimits.MAX_TRANSFER_LIMIT_TOPIC(),
      ]);
    };

    beforeEach(async () => {
      transferKey = await transferLimits["getContextKey(bytes4)"](await tokenF.TRANSFER_SELECTOR());
      transferFromKey = await transferLimits["getContextKey(bytes4)"](await tokenF.TRANSFER_FROM_SELECTOR());
    });

    it("should not apply transfer limits if context keys are not set", async () => {
      const amount = MAX_TRANSFER_LIMIT + 1n;

      await tokenF.connect(agent).mint(alice, amount);

      await expect(tokenF.connect(alice).transfer(bob, MAX_TRANSFER_LIMIT + 1n)).to.changeTokenBalances(
        tokenF,
        [alice, bob],
        [-amount, amount],
      );

      await tokenF.connect(bob).approve(alice, amount);

      await expect(tokenF.connect(alice).transferFrom(bob, alice, MAX_TRANSFER_LIMIT + 1n)).to.changeTokenBalances(
        tokenF,
        [alice, bob],
        [amount, -amount],
      );
    });

    it("should apply transfer limits if context keys are set", async () => {
      await setupHandlerTopics();

      await tokenF.connect(agent).mint(alice, MAX_TRANSFER_LIMIT + 1n);

      await expect(tokenF.connect(alice).transfer(bob, MAX_TRANSFER_LIMIT + 1n)).to.be.revertedWithCustomError(
        tokenF,
        "CannotTransfer",
      );

      await expect(tokenF.connect(alice).transfer(bob, MIN_TRANSFER_LIMIT - 1n)).to.be.revertedWithCustomError(
        tokenF,
        "CannotTransfer",
      );

      await tokenF.connect(alice).approve(bob, MAX_TRANSFER_LIMIT + 1n);

      await expect(tokenF.connect(bob).transferFrom(alice, bob, MAX_TRANSFER_LIMIT + 1n)).to.be.revertedWithCustomError(
        tokenF,
        "CannotTransfer",
      );

      await expect(tokenF.connect(bob).transferFrom(alice, bob, MIN_TRANSFER_LIMIT - 1n)).to.be.revertedWithCustomError(
        tokenF,
        "CannotTransfer",
      );
    });
  });
});
