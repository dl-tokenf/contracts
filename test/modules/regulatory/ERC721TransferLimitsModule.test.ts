import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";
import { ERC721TransferLimitsModuleMock, NFTFMock, RegulatoryComplianceMock } from "@ethers-v6";
import { SECONDS_IN_DAY, ZERO_ADDR } from "@/scripts/utils/constants";
import { AGENT_ROLE, MINT_ROLE, REGULATORY_COMPLIANCE_ROLE } from "@/test/helpers/utils";

describe("ERC721TransferLimitsModule", () => {
  const reverter = new Reverter();

  const MAX_TRANSFER_LIMIT = 10n;
  const TIME_PERIOD = SECONDS_IN_DAY;

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;
  let alice: SignerWithAddress;
  let bob: SignerWithAddress;

  let nftF: NFTFMock;
  let transferLimits: ERC721TransferLimitsModuleMock;

  before("setup", async () => {
    [owner, agent, alice, bob] = await ethers.getSigners();

    const NftFMock = await ethers.getContractFactory("NFTFMock");
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    const RegulatoryComplianceMock = await ethers.getContractFactory("RegulatoryComplianceMock");
    const ERC721TransferLimitsModuleMock = await ethers.getContractFactory("ERC721TransferLimitsModuleMock");

    nftF = await NftFMock.deploy();
    const rCompliance = await RegulatoryComplianceMock.deploy();
    const kycCompliance = await KYCComplianceMock.deploy();

    const initRegulatory = rCompliance.interface.encodeFunctionData("__RegulatoryComplianceDirect_init");
    const initKYC = kycCompliance.interface.encodeFunctionData("__KYCComplianceDirect_init");

    await nftF.__NFTFMock_init("NFT F", "NF", rCompliance, kycCompliance, initRegulatory, initKYC);

    const rComplianceProxy = RegulatoryComplianceMock.attach(nftF) as RegulatoryComplianceMock;

    await nftF.grantRole(AGENT_ROLE, agent);
    await nftF.grantRole(MINT_ROLE, agent);
    await nftF.grantRole(REGULATORY_COMPLIANCE_ROLE, agent);

    transferLimits = await ERC721TransferLimitsModuleMock.deploy();
    await transferLimits.__ERC721TransferLimitsModuleMock_init(nftF, MAX_TRANSFER_LIMIT, TIME_PERIOD);

    await rComplianceProxy.connect(agent).addRegulatoryModules([transferLimits]);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("access", () => {
    it("should initialize only once", async () => {
      await expect(transferLimits.__ERC721TransferLimitsModuleMock_init(ZERO_ADDR, 0, 0)).to.be.revertedWithCustomError(
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
      expect(await transferLimits.getMaxTransfersPerPeriod()).to.deep.eq(MAX_TRANSFER_LIMIT);
      expect(await transferLimits.getTimePeriod()).to.deep.eq(TIME_PERIOD);
    });
  });

  describe("setMaxTransfersPerPeriod", () => {
    it("should not set max transfer limit if no role", async () => {
      await nftF.revokeRole(AGENT_ROLE, agent);

      await expect(transferLimits.connect(agent).setMaxTransfersPerPeriod(MAX_TRANSFER_LIMIT + 1n))
        .to.be.revertedWithCustomError(nftF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, AGENT_ROLE);
    });

    it("should set max transfer limit if all conditions are met", async () => {
      await transferLimits.connect(agent).setMaxTransfersPerPeriod(MAX_TRANSFER_LIMIT + 1n);

      expect(await transferLimits.getMaxTransfersPerPeriod()).to.deep.eq(MAX_TRANSFER_LIMIT + 1n);
    });
  });

  describe("setTimePeriod", () => {
    it("should not set time period if no role", async () => {
      await nftF.revokeRole(AGENT_ROLE, agent);

      await expect(transferLimits.connect(agent).setTimePeriod(TIME_PERIOD + 1))
        .to.be.revertedWithCustomError(nftF, "AccessControlUnauthorizedAccount")
        .withArgs(agent, AGENT_ROLE);
    });

    it("should settime period if all conditions are met", async () => {
      await transferLimits.connect(agent).setTimePeriod(TIME_PERIOD + 1);

      expect(await transferLimits.getTimePeriod()).to.deep.eq(TIME_PERIOD + 1);
    });
  });

  describe("transferred", () => {
    it("should not call transferred from non-AssetF address", async () => {
      const ctx = {
        selector: "0x12345678",
        from: alice,
        to: bob,
        amount: 0,
        tokenId: 0,
        operator: ZERO_ADDR,
        data: "0x",
      };

      await expect(transferLimits.connect(agent).transferred(ctx))
        .to.be.revertedWithCustomError(transferLimits, "SenderNotAssetF")
        .withArgs(agent);
    });
  });

  describe("integration", () => {
    let transferKey: string;
    let transferFromKey: string;

    const tokenURI = "";

    const setupHandlerTopics = async () => {
      await transferLimits.addHandlerTopics(transferKey, [await transferLimits.MAX_TRANSFERS_PER_PERIOD_TOPIC()]);
      await transferLimits.addHandlerTopics(transferFromKey, [await transferLimits.MAX_TRANSFERS_PER_PERIOD_TOPIC()]);
    };

    beforeEach(async () => {
      transferKey = await transferLimits.getContextKey(await nftF.TRANSFER_SELECTOR());
      transferFromKey = await transferLimits.getContextKey(await nftF.TRANSFER_FROM_SELECTOR());
    });

    it("should not apply transfer limits if context keys are not set", async () => {
      const offLimitTokenId = MAX_TRANSFER_LIMIT + 1n;

      for (let tokenId = 0; tokenId <= offLimitTokenId; tokenId++) {
        await nftF.connect(agent).mint(alice, tokenId, tokenURI);

        await expect(await nftF.connect(alice).transfer(bob, tokenId)).to.not.be.reverted;
        expect(await nftF.ownerOf(tokenId)).to.be.eq(bob);
      }

      for (let tokenId = 0; tokenId <= offLimitTokenId; tokenId++) {
        await nftF.connect(bob).approve(alice, tokenId);

        await expect(await nftF.connect(alice).transferFrom(bob, alice, tokenId)).to.not.be.reverted;
        expect(await nftF.ownerOf(tokenId)).to.be.eq(alice);
      }
    });

    it("should apply transfer limits for a transfer if context keys are set", async () => {
      const offLimitTokenId = MAX_TRANSFER_LIMIT + 1n;

      await setupHandlerTopics();

      const periodOfFirstTransfer = Math.floor((await time.latest()) / TIME_PERIOD);

      for (let tokenId = 0; tokenId <= MAX_TRANSFER_LIMIT; tokenId++) {
        await nftF.connect(agent).mint(alice, tokenId, tokenURI);

        await expect(await nftF.connect(alice).transfer(bob, tokenId)).to.not.be.reverted;
        expect(await nftF.ownerOf(tokenId)).to.be.eq(bob);
      }

      await nftF.connect(agent).mint(alice, offLimitTokenId, tokenURI);
      await expect(nftF.connect(alice).transfer(bob, offLimitTokenId)).to.be.revertedWithCustomError(
        nftF,
        "CannotTransfer",
      );

      const newPeriodStartTimestamp = (periodOfFirstTransfer + 1) * TIME_PERIOD;
      await time.increaseTo(newPeriodStartTimestamp);

      await expect(await nftF.connect(alice).transfer(bob, offLimitTokenId)).to.not.be.reverted;
      expect(await nftF.ownerOf(offLimitTokenId)).to.be.eq(bob);
    });

    it("should apply transfer limits for a transferFrom if context keys are set", async () => {
      await setupHandlerTopics();

      const offLimitTokenId = MAX_TRANSFER_LIMIT + 1n;

      for (let tokenId = 0; tokenId <= MAX_TRANSFER_LIMIT; tokenId++) {
        await nftF.connect(agent).mint(alice, tokenId, tokenURI);
        await nftF.connect(alice).approve(bob, tokenId);

        await expect(await nftF.connect(bob).transferFrom(alice, bob, tokenId)).to.not.be.reverted;
        expect(await nftF.ownerOf(tokenId)).to.be.eq(bob);
      }

      await nftF.connect(agent).mint(alice, offLimitTokenId, tokenURI);
      await nftF.connect(alice).approve(bob, offLimitTokenId);

      await expect(nftF.connect(bob).transferFrom(alice, bob, offLimitTokenId)).to.be.revertedWithCustomError(
        nftF,
        "CannotTransfer",
      );

      await time.increase(TIME_PERIOD + 1);

      await expect(await nftF.connect(bob).transferFrom(alice, bob, offLimitTokenId)).to.not.be.reverted;
      expect(await nftF.ownerOf(offLimitTokenId)).to.be.eq(bob);
    });
  });
});
