import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import {
  KYCComplianceFacet,
  KYCComplianceFacet__factory,
  EquityRarimoModule,
  EquityRarimoModule__factory,
  RegulatoryComplianceFacet,
  RegulatoryComplianceFacet__factory,
  EquityToken,
  EquityToken__factory,
  EquityERC20TransferLimitsModule,
  EquityERC20TransferLimitsModule__factory,
  RarimoSBT,
  RarimoSBT__factory,
} from "@ethers-v6";

async function setupCoreContracts(
  deployer: Deployer,
): Promise<[EquityToken, KYCComplianceFacet, RegulatoryComplianceFacet]> {
  const tokenF = await deployer.deploy(EquityToken__factory);
  const kycCompliance = await deployer.deploy(KYCComplianceFacet__factory);
  const regulatoryCompliance = await deployer.deploy(RegulatoryComplianceFacet__factory);

  const regulatoryComplianceInitData = regulatoryCompliance.interface.encodeFunctionData(
    "__RegulatoryComplianceFacet_init",
  );
  const kycComplianceInitData = kycCompliance.interface.encodeFunctionData("__KYCComplianceFacet_init");

  await tokenF.__EquityToken_init(
    regulatoryCompliance,
    kycCompliance,
    regulatoryComplianceInitData,
    kycComplianceInitData,
  );

  return [
    tokenF,
    kycCompliance.attach(tokenF) as KYCComplianceFacet,
    regulatoryCompliance.attach(tokenF) as RegulatoryComplianceFacet,
  ];
}

async function setupTransferLimitsModule(
  deployer: Deployer,
  tokenF: EquityToken,
): Promise<EquityERC20TransferLimitsModule> {
  const transferLimitsModule = await deployer.deploy(EquityERC20TransferLimitsModule__factory);
  await transferLimitsModule.__EquityERC20TransferLimitsModule_init(tokenF);

  const transferContextKey = await transferLimitsModule.getContextKey(await tokenF.TRANSFER_SELECTOR());
  const transferFromContextKey = await transferLimitsModule.getContextKey(await tokenF.TRANSFER_FROM_SELECTOR());

  await transferLimitsModule.addHandlerTopics(transferContextKey, [
    await transferLimitsModule.MIN_TRANSFER_LIMIT_TOPIC(),
    await transferLimitsModule.MAX_TRANSFER_LIMIT_TOPIC(),
  ]);
  await transferLimitsModule.addHandlerTopics(transferFromContextKey, [
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

  const transferContextKey = await rarimoModule.getContextKey(await tokenF.TRANSFER_SELECTOR());
  const transferFromContextKey = await rarimoModule.getContextKey(await tokenF.TRANSFER_FROM_SELECTOR());

  await rarimoModule.addHandlerTopics(transferContextKey, [
    await rarimoModule.HAS_SOUL_SENDER_TOPIC(),
    await rarimoModule.HAS_SOUL_RECIPIENT_TOPIC(),
  ]);
  await rarimoModule.addHandlerTopics(transferFromContextKey, [
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
    ["ERC20TransferLimitsModule", await transferLimitsModule.getAddress()],
    ["RarimoModule", await rarimoModule.getAddress()],
    ["RarimoSBT", await rarimoSBT.getAddress()],
  );
};
