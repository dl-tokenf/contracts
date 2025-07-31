import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import {
  KYCComplianceFacet,
  KYCComplianceFacet__factory,
  EquityKYCModule,
  EquityKYCModule__factory,
  RegulatoryComplianceFacet,
  RegulatoryComplianceFacet__factory,
  EquityToken,
  EquityToken__factory,
  EquityERC20TransferLimitsModule,
  EquityERC20TransferLimitsModule__factory,
  EquitySBT,
  EquitySBT__factory,
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

  const transferContextKey = await transferLimitsModule.getContextKeyBySelector(await tokenF.TRANSFER_SELECTOR());
  const transferFromContextKey = await transferLimitsModule.getContextKeyBySelector(
    await tokenF.TRANSFER_FROM_SELECTOR(),
  );

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

async function setupKYCModule(deployer: Deployer, tokenF: EquityToken): Promise<[EquityKYCModule, EquitySBT]> {
  const equitySBT = await deployer.deploy(EquitySBT__factory);
  await equitySBT.__EquitySBT_init();

  const equityKYCModule = await deployer.deploy(EquityKYCModule__factory);
  await equityKYCModule.__EquityKYCModule_init(tokenF, equitySBT);

  const transferContextKey = await equityKYCModule.getContextKeyBySelector(await tokenF.TRANSFER_SELECTOR());
  const transferFromContextKey = await equityKYCModule.getContextKeyBySelector(await tokenF.TRANSFER_FROM_SELECTOR());

  await equityKYCModule.addHandlerTopics(transferContextKey, [
    await equityKYCModule.HAS_SOUL_SENDER_TOPIC(),
    await equityKYCModule.HAS_SOUL_RECIPIENT_TOPIC(),
  ]);
  await equityKYCModule.addHandlerTopics(transferFromContextKey, [
    await equityKYCModule.HAS_SOUL_SENDER_TOPIC(),
    await equityKYCModule.HAS_SOUL_RECIPIENT_TOPIC(),
    await equityKYCModule.HAS_SOUL_OPERATOR_TOPIC(),
  ]);

  return [equityKYCModule, equitySBT];
}

export = async (deployer: Deployer) => {
  const [tokenF, kycCompliance, regulatoryCompliance] = await setupCoreContracts(deployer);

  const [equityKYCModule, equitySBT] = await setupKYCModule(deployer, tokenF);
  const transferLimitsModule = await setupTransferLimitsModule(deployer, tokenF);

  await kycCompliance.addKYCModules([equityKYCModule]);
  await regulatoryCompliance.addRegulatoryModules([transferLimitsModule]);

  Reporter.reportContracts(
    ["EquityToken", await tokenF.getAddress()],
    ["ERC20TransferLimitsModule", await transferLimitsModule.getAddress()],
    ["EquityKYCModule", await equityKYCModule.getAddress()],
    ["EquitySBT", await equitySBT.getAddress()],
  );
};
