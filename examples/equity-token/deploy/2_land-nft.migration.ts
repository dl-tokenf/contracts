import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import {
  KYCComplianceFacet,
  KYCComplianceFacet__factory,
  LandNFT,
  LandNFT__factory,
  EquityKYCModule,
  EquityKYCModule__factory,
  RegulatoryComplianceFacet,
  RegulatoryComplianceFacet__factory,
  EquitySBT,
  EquitySBT__factory,
  LandERC721TransferLimitsModule,
  LandERC721TransferLimitsModule__factory,
} from "@ethers-v6";

async function setupCoreContracts(
  deployer: Deployer,
): Promise<[LandNFT, KYCComplianceFacet, RegulatoryComplianceFacet]> {
  const nftF = await deployer.deploy(LandNFT__factory);
  const kycCompliance = await deployer.deploy(KYCComplianceFacet__factory);
  const regulatoryCompliance = await deployer.deploy(RegulatoryComplianceFacet__factory);

  const regulatoryComplianceInitData = regulatoryCompliance.interface.encodeFunctionData(
    "__RegulatoryComplianceFacet_init",
  );
  const kycComplianceInitData = kycCompliance.interface.encodeFunctionData("__KYCComplianceFacet_init");

  await nftF.__LandNFT_init(regulatoryCompliance, kycCompliance, regulatoryComplianceInitData, kycComplianceInitData);

  return [
    nftF,
    kycCompliance.attach(nftF) as KYCComplianceFacet,
    regulatoryCompliance.attach(nftF) as RegulatoryComplianceFacet,
  ];
}

async function setupTransferLimitsModule(deployer: Deployer, nftF: LandNFT): Promise<LandERC721TransferLimitsModule> {
  const transferLimitsModule = await deployer.deploy(LandERC721TransferLimitsModule__factory);
  await transferLimitsModule.__LandERC721TransferLimitsModule_init(nftF);

  const transferContextKey = await transferLimitsModule.getContextKeyBySelector(await nftF.TRANSFER_SELECTOR());
  const transferFromContextKey = await transferLimitsModule.getContextKeyBySelector(
    await nftF.TRANSFER_FROM_SELECTOR(),
  );

  await transferLimitsModule.addHandlerTopics(transferContextKey, [
    await transferLimitsModule.MAX_TRANSFERS_PER_PERIOD_TOPIC(),
  ]);
  await transferLimitsModule.addHandlerTopics(transferFromContextKey, [
    await transferLimitsModule.MAX_TRANSFERS_PER_PERIOD_TOPIC(),
  ]);

  return transferLimitsModule;
}

async function setupKYCModule(deployer: Deployer, nftF: LandNFT): Promise<[EquityKYCModule, EquitySBT]> {
  const equitySBT = await deployer.deploy(EquitySBT__factory);
  await equitySBT.__EquitySBT_init();

  const equityKYCModule = await deployer.deploy(EquityKYCModule__factory);
  await equityKYCModule.__EquityKYCModule_init(nftF, equitySBT);

  const transferContextKey = await equityKYCModule.getContextKeyBySelector(await nftF.TRANSFER_SELECTOR());
  const transferFromContextKey = await equityKYCModule.getContextKeyBySelector(await nftF.TRANSFER_FROM_SELECTOR());
  const safeTransferFromContextKey = await equityKYCModule.getContextKeyBySelector(
    await nftF.SAFE_TRANSFER_FROM_SELECTOR(),
  );
  const safeTransferFromWithDataContextKey = await equityKYCModule.getContextKeyBySelector(
    await nftF.SAFE_TRANSFER_FROM_WITH_DATA_SELECTOR(),
  );

  await equityKYCModule.addHandlerTopics(transferContextKey, [
    await equityKYCModule.HAS_SOUL_SENDER_TOPIC(),
    await equityKYCModule.HAS_SOUL_RECIPIENT_TOPIC(),
  ]);
  await equityKYCModule.addHandlerTopics(transferFromContextKey, [
    await equityKYCModule.HAS_SOUL_SENDER_TOPIC(),
    await equityKYCModule.HAS_SOUL_RECIPIENT_TOPIC(),
    await equityKYCModule.HAS_SOUL_OPERATOR_TOPIC(),
  ]);
  await equityKYCModule.addHandlerTopics(safeTransferFromContextKey, [
    await equityKYCModule.HAS_SOUL_SENDER_TOPIC(),
    await equityKYCModule.HAS_SOUL_RECIPIENT_TOPIC(),
    await equityKYCModule.HAS_SOUL_OPERATOR_TOPIC(),
  ]);
  await equityKYCModule.addHandlerTopics(safeTransferFromWithDataContextKey, [
    await equityKYCModule.HAS_SOUL_SENDER_TOPIC(),
    await equityKYCModule.HAS_SOUL_RECIPIENT_TOPIC(),
    await equityKYCModule.HAS_SOUL_OPERATOR_TOPIC(),
  ]);

  return [equityKYCModule, equitySBT];
}

export = async (deployer: Deployer) => {
  const [nftF, kycCompliance, regulatoryCompliance] = await setupCoreContracts(deployer);

  const [equityKYCModule, equitySBT] = await setupKYCModule(deployer, nftF);
  const transferLimitsModule = await setupTransferLimitsModule(deployer, nftF);

  await kycCompliance.addKYCModules([equityKYCModule]);
  await regulatoryCompliance.addRegulatoryModules([transferLimitsModule]);

  Reporter.reportContracts(
    ["LandNFT", await nftF.getAddress()],
    ["ERC20TransferLimitsModule", await transferLimitsModule.getAddress()],
    ["EquityKYCModule", await equityKYCModule.getAddress()],
    ["EquitySBT", await equitySBT.getAddress()],
  );
};
