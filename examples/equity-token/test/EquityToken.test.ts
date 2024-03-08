import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { Reverter } from "@/test/helpers/reverter";
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
      await _regulatoryCompliance.getAddress(),
      await _kycCompliance.getAddress(),
      _regulatoryCompliance.interface.encodeFunctionData("__EquityRegulatoryCompliance_init"),
      _kycCompliance.interface.encodeFunctionData("__EquityKYCCompliance_init"),
    );

    kycCompliance = _kycCompliance.attach(token) as EquityKYCCompliance;
    regulatoryCompliance = _regulatoryCompliance.attach(token) as EquityRegulatoryCompliance;

    rarimoModule = await EquityRarimoModule.deploy();
    transferLimitsModule = await EquityTransferLimitsModule.deploy();

    rarimoSBT = await RarimoSBT.deploy();

    await rarimoSBT.__RarimoSBT_init();

    await transferLimitsModule.__EquityTransferLimitsModule_init(await token.getAddress());
    await rarimoModule.__EquityRarimoModule_init(await token.getAddress(), await rarimoSBT.getAddress());

    await kycCompliance.addKYCModules([rarimoModule]);
    await regulatoryCompliance.addRegulatoryModules([transferLimitsModule]);

    await token.grantRole(await token.AGENT_ROLE(), agent);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  context("happy flow", () => {
    beforeEach(async () => {});

    it.only("test", async () => {
      console.log("works");
    });
  });
});
