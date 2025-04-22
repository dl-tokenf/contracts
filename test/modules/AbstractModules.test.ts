import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { ModuleMock, RegulatoryComplianceMock, TokenFMock } from "@ethers-v6";
import { ZERO_ADDR, ZERO_BYTES32, ZERO_SELECTOR } from "@/scripts/utils/constants";
import { AGENT_ROLE, REGULATORY_COMPLIANCE_ROLE } from "@/test/helpers/utils";

describe("AbstractModules", () => {
  const reverter = new Reverter();

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;

  let tokenF: TokenFMock;
  let module: ModuleMock;

  before("setup", async () => {
    [owner, agent] = await ethers.getSigners();

    const TokenFMock = await ethers.getContractFactory("TokenFMock");
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    const RegulatoryComplianceMock = await ethers.getContractFactory("RegulatoryComplianceMock");
    const ModuleMock = await ethers.getContractFactory("ModuleMock");

    tokenF = await TokenFMock.deploy();
    const rCompliance = await RegulatoryComplianceMock.deploy();
    const kycCompliance = await KYCComplianceMock.deploy();

    const initRegulatory = rCompliance.interface.encodeFunctionData("__RegulatoryComplianceDirect_init");
    const initKYC = kycCompliance.interface.encodeFunctionData("__KYCComplianceDirect_init");

    await tokenF.__TokenFMock_init("TokenF", "TF", rCompliance, kycCompliance, initRegulatory, initKYC);

    const rComplianceProxy = RegulatoryComplianceMock.attach(tokenF) as RegulatoryComplianceMock;

    await tokenF.grantRole(AGENT_ROLE, agent);
    await tokenF.grantRole(REGULATORY_COMPLIANCE_ROLE, agent);

    module = await ModuleMock.deploy();
    await module.__ModuleMock_init(tokenF);

    await rComplianceProxy.connect(agent).addRegulatoryModules([module]);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(module.__ModuleMock_init(ZERO_ADDR)).to.be.revertedWithCustomError(module, "InvalidInitialization");
    });

    it("should initialize only by top level contract", async () => {
      await expect(module.__AbstractModuleDirect_init()).to.be.revertedWithCustomError(module, "NotInitializing");

      await expect(module.__AbstractRegulatoryModuleDirect_init()).to.be.revertedWithCustomError(
        module,
        "NotInitializing",
      );

      await expect(module.__AbstractKYCModuleDirect_init()).to.be.revertedWithCustomError(module, "NotInitializing");
    });
  });

  describe("getters", () => {
    it("should return base data", async () => {
      expect(await module.getAssetF()).to.eq(tokenF);
    });
  });

  describe("AbstractModule", () => {
    describe("handlerer", () => {
      it("should not handle if handler is not set", async () => {
        await module
          .connect(agent)
          .addHandlerTopics(await module.getContextKey(await tokenF.MINT_SELECTOR()), [await module.MOCK_TOPIC()]);

        await expect(
          module.canTransfer({
            selector: await tokenF.MINT_SELECTOR(),
            from: ZERO_ADDR,
            to: ZERO_ADDR,
            amount: 0,
            tokenId: 0,
            operator: ZERO_ADDR,
            data: "0x",
          }),
        ).to.be.revertedWithCustomError(module, "HandlerNotSet");
      });

      it("should handle if all conditions are met", async () => {
        await module
          .connect(agent)
          .addHandlerTopics(await module.getContextKey(await tokenF.MINT_SELECTOR()), [await module.MOCK_TOPIC()]);

        await module.handlerer();

        expect(
          await module.canTransfer({
            selector: await tokenF.MINT_SELECTOR(),
            from: ZERO_ADDR,
            to: ZERO_ADDR,
            amount: 0,
            tokenId: 0,
            operator: ZERO_ADDR,
            data: "0x",
          }),
        ).to.be.true;
      });
    });

    describe("addHandlerTopics", () => {
      it("should not add handler topics if no role", async () => {
        await tokenF.revokeRole(AGENT_ROLE, agent);

        await expect(module.connect(agent).addHandlerTopics(ZERO_BYTES32, [ZERO_BYTES32]))
          .to.be.revertedWithCustomError(tokenF, "AccessControlUnauthorizedAccount")
          .withArgs(agent, AGENT_ROLE);
      });

      it("should not add handler topics if duplicates", async () => {
        await expect(module.connect(agent).addHandlerTopics(ZERO_BYTES32, [ZERO_BYTES32, ZERO_BYTES32]))
          .to.be.revertedWithCustomError(module, "ElementAlreadyExistsBytes32")
          .withArgs(ZERO_BYTES32);
      });

      it("should add handler topics if all conditions are met", async () => {
        await module.connect(agent).addHandlerTopics(ZERO_BYTES32, [ZERO_BYTES32]);

        expect(await module.getHandlerTopics(ZERO_BYTES32)).to.deep.eq([ZERO_BYTES32]);
      });
    });

    describe("removeHandlerTopics", () => {
      it("should not remove handler topics if no role", async () => {
        await tokenF.revokeRole(AGENT_ROLE, agent);

        await expect(module.connect(agent).removeHandlerTopics(ZERO_BYTES32, [ZERO_BYTES32]))
          .to.be.revertedWithCustomError(tokenF, "AccessControlUnauthorizedAccount")
          .withArgs(agent, AGENT_ROLE);
      });

      it("should not remove handler topics if no handler topic", async () => {
        await expect(module.connect(agent).removeHandlerTopics(ZERO_BYTES32, [ZERO_BYTES32]))
          .to.be.revertedWithCustomError(module, "NoSuchBytes32")
          .withArgs(ZERO_BYTES32);
      });

      it("should remove handler topics if all conditions are met", async () => {
        await module.connect(agent).addHandlerTopics(ZERO_BYTES32, [ZERO_BYTES32]);
        await module.connect(agent).removeHandlerTopics(ZERO_BYTES32, [ZERO_BYTES32]);

        expect(await module.getHandlerTopics(ZERO_BYTES32)).to.deep.eq([]);
      });
    });
  });

  describe("AbstractRegulatoryModule", () => {
    describe("transferred", () => {
      it("should not transfer if not TokenF", async () => {
        await expect(
          module.transferred({
            selector: ZERO_SELECTOR,
            from: ZERO_ADDR,
            to: ZERO_ADDR,
            amount: 0,
            tokenId: 0,
            operator: ZERO_ADDR,
            data: "0x",
          }),
        )
          .to.be.revertedWithCustomError(module, "SenderNotAssetF")
          .withArgs(owner);
      });
    });
  });
});
