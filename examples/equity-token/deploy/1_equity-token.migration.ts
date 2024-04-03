import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import {
  EquityKYCCompliance,
  EquityKYCCompliance__factory,
  EquityRarimoModule,
  EquityRarimoModule__factory,
  EquityRegulatoryCompliance,
  EquityRegulatoryCompliance__factory,
  EquityToken,
  EquityToken__factory,
  EquityTransferLimitsModule,
  EquityTransferLimitsModule__factory,
  RarimoSBT,
  RarimoSBT__factory,
} from "@ethers-v6";

async function setupCoreContracts(
  deployer: Deployer,
): Promise<[EquityToken, EquityKYCCompliance, EquityRegulatoryCompliance]> {
  const tokenF = await deployer.deploy(EquityToken__factory);
  const kycCompliance = await deployer.deploy(EquityKYCCompliance__factory);
  const regulatoryCompliance = await deployer.deploy(EquityRegulatoryCompliance__factory);

  const regulatoryComplianceInitData = regulatoryCompliance.interface.encodeFunctionData(
    "__EquityRegulatoryCompliance_init",
  );
  const kycComplianceInitData = kycCompliance.interface.encodeFunctionData("__EquityKYCCompliance_init");

  await tokenF.__EquityToken_init(
    regulatoryCompliance,
    kycCompliance,
    regulatoryComplianceInitData,
    kycComplianceInitData,
  );

  return [
    tokenF,
    kycCompliance.attach(tokenF) as EquityKYCCompliance,
    regulatoryCompliance.attach(tokenF) as EquityRegulatoryCompliance,
  ];
}

async function setupTransferLimitsModule(deployer: Deployer, tokenF: EquityToken): Promise<EquityTransferLimitsModule> {
  const transferLimitsModule = await deployer.deploy(EquityTransferLimitsModule__factory);
  await transferLimitsModule.__EquityTransferLimitsModule_init(tokenF);

  const transferClaimTopicKey = await transferLimitsModule.getClaimTopicKey(await tokenF.TRANSFER_SELECTOR());
  const transferFromClaimTopicKey = await transferLimitsModule.getClaimTopicKey(await tokenF.TRANSFER_FROM_SELECTOR());

  await transferLimitsModule.addClaimTopics(transferClaimTopicKey, [
    await transferLimitsModule.MIN_TRANSFER_LIMIT_TOPIC(),
    await transferLimitsModule.MAX_TRANSFER_LIMIT_TOPIC(),
  ]);
  await transferLimitsModule.addClaimTopics(transferFromClaimTopicKey, [
    await transferLimitsModule.MIN_TRANSFER_LIMIT_TOPIC(),
    await transferLimitsModule.MAX_TRANSFER_LIMIT_TOPIC(),
  ]);

  return transferLimitsModule;
}

async function setupRarimoModule(deployer: Deployer, tokenF: EquityToken): Promise<[EquityRarimoModule, RarimoSBT]> {
  const rarimoSBT = await deployer.deploy(RarimoSBT__factory);
  await rarimoSBT.__RarimoSBT_init();

  const rarimoModule = await deployer.deploy(EquityRarimoModule__factory);
  await rarimoModule.__EquityRarimoModule_init(tokenF, rarimoSBT);

  await tokenF.TRANSFER_SELECTOR();
  const transferClaimTopicKey = await rarimoModule.getClaimTopicKey("0x57f99789");
  const transferFromClaimTopicKey = await rarimoModule.getClaimTopicKey(await tokenF.TRANSFER_FROM_SELECTOR());

  await rarimoModule.addClaimTopics(transferClaimTopicKey, [
    await rarimoModule.HAS_SOUL_SENDER_TOPIC(),
    await rarimoModule.HAS_SOUL_RECIPIENT_TOPIC(),
  ]);
  await rarimoModule.addClaimTopics(transferFromClaimTopicKey, [
    await rarimoModule.HAS_SOUL_SENDER_TOPIC(),
    await rarimoModule.HAS_SOUL_RECIPIENT_TOPIC(),
    await rarimoModule.HAS_SOUL_OPERATOR_TOPIC(),
  ]);

  return [rarimoModule, rarimoSBT];
}

export = async (deployer: Deployer) => {
  const [tokenF, kycCompliance, regulatoryCompliance] = await setupCoreContracts(deployer);

  const [rarimoModule, rarimoSBT] = await setupRarimoModule(deployer, tokenF);
  const transferLimitsModule = await setupTransferLimitsModule(deployer, tokenF);

  await kycCompliance.addKYCModules([rarimoModule]);
  await regulatoryCompliance.addRegulatoryModules([transferLimitsModule]);

  Reporter.reportContracts(
    ["EquityToken", await tokenF.getAddress()],
    ["TransferLimitsModule", await transferLimitsModule.getAddress()],
    ["RarimoModule", await rarimoModule.getAddress()],
    ["RarimoSBT", await rarimoSBT.getAddress()],
  );
};
