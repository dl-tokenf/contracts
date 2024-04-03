import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { KYCComplianceMock, RarimoModuleMock, SBTMock, TokenFMock } from "@ethers-v6";
import { ZERO_ADDR } from "@/scripts/utils/constants";
import { KYC_COMPLIANCE_ROLE, MINT_ROLE } from "@/test/helpers/utils";
import { wei } from "@/scripts/utils/utils";

describe("RarimoModule", () => {
  const reverter = new Reverter();

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;
  let alice: SignerWithAddress;
  let bob: SignerWithAddress;

  let tokenF: TokenFMock;
  let rarimo: RarimoModuleMock;
  let sbt: SBTMock;

  before("setup", async () => {
    [owner, agent, alice, bob] = await ethers.getSigners();

    const TokenFMock = await ethers.getContractFactory("TokenFMock");
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    const RegulatoryComplianceMock = await ethers.getContractFactory("RegulatoryComplianceMock");
    const RarimoModuleMock = await ethers.getContractFactory("RarimoModuleMock");
    const SBTMock = await ethers.getContractFactory("SBTMock");

    tokenF = await TokenFMock.deploy();
    const rCompliance = await RegulatoryComplianceMock.deploy();
    const kycCompliance = await KYCComplianceMock.deploy();

    const initRegulatory = rCompliance.interface.encodeFunctionData("__RegulatoryComplianceMock_init");
    const initKYC = kycCompliance.interface.encodeFunctionData("__KYCComplianceMock_init");

    await tokenF.__TokenFMock_init("TokenF", "TF", rCompliance, kycCompliance, initRegulatory, initKYC);

    const kycComplianceProxy = KYCComplianceMock.attach(tokenF) as KYCComplianceMock;

    await tokenF.grantRole(MINT_ROLE, agent);
    await tokenF.grantRole(KYC_COMPLIANCE_ROLE, agent);

    sbt = await SBTMock.deploy();
    await sbt.__SBTMock_init();

    rarimo = await RarimoModuleMock.deploy();
    await rarimo.__RarimoModuleMock_init(tokenF, sbt);

    await kycComplianceProxy.connect(agent).addKYCModules([rarimo]);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(rarimo.__RarimoModuleMock_init(ZERO_ADDR, ZERO_ADDR)).to.be.revertedWith(
        "Initializable: contract is already initialized",
      );
    });

    it("should initialize only by top level contract", async () => {
      await expect(rarimo.__RarimoModuleDirect_init()).to.be.revertedWith(
        "Initializable: contract is not initializing",
      );
    });
  });

  describe("getters", () => {
    it("should return base data", async () => {
      expect(await rarimo.getSBT()).to.eq(await sbt.getAddress());
    });
  });

  describe("integration", () => {
    let transferKey: string;
    let transferFromKey: string;

    const setupClaimTopics = async () => {
      await rarimo.addClaimTopics(transferKey, [
        await rarimo.HAS_SOUL_SENDER_TOPIC(),
        await rarimo.HAS_SOUL_RECIPIENT_TOPIC(),
      ]);
      await rarimo.addClaimTopics(transferFromKey, [
        await rarimo.HAS_SOUL_SENDER_TOPIC(),
        await rarimo.HAS_SOUL_RECIPIENT_TOPIC(),
        await rarimo.HAS_SOUL_OPERATOR_TOPIC(),
      ]);
    };

    beforeEach(async () => {
      transferKey = await rarimo.getClaimTopicKey(await tokenF.TRANSFER_SELECTOR());
      transferFromKey = await rarimo.getClaimTopicKey(await tokenF.TRANSFER_FROM_SELECTOR());
    });

    it("should not apply kyc limits if claim topic keys are not set", async () => {
      await tokenF.connect(agent).mint(alice, wei("1"));

      await expect(tokenF.connect(alice).transfer(agent, wei("1"))).to.changeTokenBalances(
        tokenF,
        [alice, agent],
        [-wei("1"), wei("1")],
      );

      await tokenF.connect(agent).approve(alice, wei("1"));

      await expect(tokenF.connect(alice).transferFrom(agent, bob, wei("1"))).to.changeTokenBalances(
        tokenF,
        [agent, bob],
        [-wei("1"), wei("1")],
      );
    });

    it("should apply kyc limits if claim topic keys are set", async () => {
      await setupClaimTopics();

      await tokenF.connect(agent).mint(alice, wei("1"));

      await expect(tokenF.connect(alice).transfer(agent, wei("1"))).to.be.revertedWith("TokenF: not KYCed");

      await tokenF.connect(agent).approve(alice, wei("1"));

      await expect(tokenF.connect(alice).transferFrom(agent, bob, wei("1"))).to.be.revertedWith("TokenF: not KYCed");
    });

    it("should transfer if sbt tokens are minted", async () => {
      await setupClaimTopics();

      await sbt.mint(agent, 1);
      await sbt.mint(alice, 2);
      await sbt.mint(bob, 3);

      await tokenF.connect(agent).mint(alice, wei("1"));

      await expect(tokenF.connect(alice).transfer(agent, wei("1"))).to.changeTokenBalances(
        tokenF,
        [alice, agent],
        [-wei("1"), wei("1")],
      );

      await tokenF.connect(agent).approve(alice, wei("1"));

      await expect(tokenF.connect(alice).transferFrom(agent, bob, wei("1"))).to.changeTokenBalances(
        tokenF,
        [agent, bob],
        [-wei("1"), wei("1")],
      );
    });
  });
});
