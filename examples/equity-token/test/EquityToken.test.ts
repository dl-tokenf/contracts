import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { wei } from "@/scripts/utils/utils";
import { Reverter } from "@/test/helpers/reverter";
import { TransferParty } from "@/test/helpers/types";
import {
  EquityKYCCompliance,
  EquityRarimoModule,
  EquityRegulatoryCompliance,
  EquityToken,
  EquityTransferLimitsModule,
  RarimoSBT,
} from "@ethers-v6";

describe("EquityToken", () => {
  const reverter = new Reverter();

  let owner: SignerWithAddress;
  let agent: SignerWithAddress;
  let bob: SignerWithAddress;
  let alice: SignerWithAddress;

  let token: EquityToken;
  let kycCompliance: EquityKYCCompliance;
  let regulatoryCompliance: EquityRegulatoryCompliance;
  let transferLimitsModule: EquityTransferLimitsModule;
  let rarimoModule: EquityRarimoModule;
  let rarimoSBT: RarimoSBT;

  const setupRarimoModule = async () => {
    const operatorMintKey = await rarimoModule.getClaimTopicKey(await token.MINT_SELECTOR(), TransferParty.Operator);
    const toMintKey = await rarimoModule.getClaimTopicKey(await token.MINT_SELECTOR(), TransferParty.Recipient);

    const fromTransferKey = await rarimoModule.getClaimTopicKey(await token.TRANSFER_SELECTOR(), TransferParty.Sender);
    const toTransferKey = await rarimoModule.getClaimTopicKey(await token.TRANSFER_SELECTOR(), TransferParty.Recipient);

    const fromTransferFromKey = await rarimoModule.getClaimTopicKey(
      await token.TRANSFER_FROM_SELECTOR(),
      TransferParty.Sender,
    );
    const toTransferFromKey = await rarimoModule.getClaimTopicKey(
      await token.TRANSFER_FROM_SELECTOR(),
      TransferParty.Recipient,
    );

    await rarimoModule.addClaimTopics(operatorMintKey, [await rarimoModule.HAS_SOUL_OPERATOR_TOPIC()]);

    await rarimoModule.addClaimTopics(toMintKey, [await rarimoModule.HAS_SOUL_RECIPIENT_TOPIC()]);
    await rarimoModule.addClaimTopics(toTransferKey, [await rarimoModule.HAS_SOUL_RECIPIENT_TOPIC()]);
    await rarimoModule.addClaimTopics(toTransferFromKey, [await rarimoModule.HAS_SOUL_RECIPIENT_TOPIC()]);

    await rarimoModule.addClaimTopics(fromTransferKey, [await rarimoModule.HAS_SOUL_SENDER_TOPIC()]);
    await rarimoModule.addClaimTopics(fromTransferFromKey, [await rarimoModule.HAS_SOUL_SENDER_TOPIC()]);
  };

  const setupTransferLimitsModule = async () => {
    const transferKey = await transferLimitsModule.getClaimTopicKey(await token.TRANSFER_SELECTOR());
    const transferFromKey = await transferLimitsModule.getClaimTopicKey(await token.TRANSFER_FROM_SELECTOR());

    await transferLimitsModule.addClaimTopics(transferKey, [await transferLimitsModule.MIN_TRANSFER_LIMIT_TOPIC()]);
    await transferLimitsModule.addClaimTopics(transferFromKey, [await transferLimitsModule.MIN_TRANSFER_LIMIT_TOPIC()]);
  };

  before("setup", async () => {
    [owner, agent, bob, alice] = await ethers.getSigners();

    const EquityToken = await ethers.getContractFactory("EquityToken");
    const EquityKYCCompliance = await ethers.getContractFactory("EquityKYCCompliance");
    const EquityRegulatoryCompliance = await ethers.getContractFactory("EquityRegulatoryCompliance");
    const EquityTransferLimitsModule = await ethers.getContractFactory("EquityTransferLimitsModule");
    const EquityRarimoModule = await ethers.getContractFactory("EquityRarimoModule");
    const RarimoSBT = await ethers.getContractFactory("RarimoSBT");

    token = await EquityToken.deploy();

    const _kycCompliance = await EquityKYCCompliance.deploy();
    const _regulatoryCompliance = await EquityRegulatoryCompliance.deploy();

    await token.__EquityToken_init(
      _regulatoryCompliance,
      _kycCompliance,
      _regulatoryCompliance.interface.encodeFunctionData("__EquityRegulatoryCompliance_init"),
      _kycCompliance.interface.encodeFunctionData("__EquityKYCCompliance_init"),
    );

    kycCompliance = _kycCompliance.attach(token) as EquityKYCCompliance;
    regulatoryCompliance = _regulatoryCompliance.attach(token) as EquityRegulatoryCompliance;

    rarimoModule = await EquityRarimoModule.deploy();
    transferLimitsModule = await EquityTransferLimitsModule.deploy();

    rarimoSBT = await RarimoSBT.deploy();

    await rarimoSBT.__RarimoSBT_init();

    await transferLimitsModule.__EquityTransferLimitsModule_init(token);
    await rarimoModule.__EquityRarimoModule_init(token, rarimoSBT);

    await kycCompliance.addKYCModules([rarimoModule]);
    await regulatoryCompliance.addRegulatoryModules([transferLimitsModule]);

    await token.grantRole(await token.AGENT_ROLE(), agent);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  context("if restrictions are setup", () => {
    beforeEach(async () => {
      await setupRarimoModule();
      await setupTransferLimitsModule();
    });

    it("should not mint if transfer party has no role", async () => {
      await expect(token.mint(alice, wei(1))).to.be.revertedWith("TokenF: not KYCed");
    });

    it("should mint if all conditions are met", async () => {
      await rarimoSBT.mint(owner, 1);
      await rarimoSBT.mint(alice, 2);

      await token.mint(alice, wei(1));

      expect(await token.balanceOf(alice)).to.eq(wei(1));
    });
  });
});
