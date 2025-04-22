import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import {
  EquityKYCCompliance,
  EquityKYCCompliance__factory,
  LandNFT,
  LandNFT__factory,
  EquityRarimoModule,
  EquityRarimoModule__factory,
  EquityRegulatoryCompliance__factory,
  RarimoSBT,
  RarimoSBT__factory,
  EquityRegulatoryCompliance,
  LandERC721TransferLimitsModule,
  LandERC721TransferLimitsModule__factory,
} from "@ethers-v6";

async function setupCoreContracts(deployer: Deployer): Promise<[LandNFT, EquityKYCCompliance, EquityRegulatoryCompliance]> {
  const nftF = await deployer.deploy(LandNFT__factory);
  const kycCompliance = await deployer.deploy(EquityKYCCompliance__factory);
  const regulatoryCompliance = await deployer.deploy(EquityRegulatoryCompliance__factory);

  const regulatoryComplianceInitData = regulatoryCompliance.interface.encodeFunctionData(
    "__EquityRegulatoryCompliance_init",
  );
  const kycComplianceInitData = kycCompliance.interface.encodeFunctionData("__EquityKYCCompliance_init");

  await nftF.__LandNFT_init(regulatoryCompliance, kycCompliance, regulatoryComplianceInitData, kycComplianceInitData);

  return [nftF, kycCompliance.attach(nftF) as EquityKYCCompliance, regulatoryCompliance.attach(nftF) as EquityRegulatoryCompliance];
}

async function setupTransferLimitsModule(
  deployer: Deployer,
  nftF: LandNFT,
): Promise<LandERC721TransferLimitsModule> {
  const transferLimitsModule = await deployer.deploy(LandERC721TransferLimitsModule__factory);
  await transferLimitsModule.__LandERC721TransferLimitsModule_init(nftF);

  const transferContextKey = await transferLimitsModule.getContextKey(await nftF.TRANSFER_SELECTOR());
  const transferFromContextKey = await transferLimitsModule.getContextKey(await nftF.TRANSFER_FROM_SELECTOR());

  await transferLimitsModule.addHandlerTopics(transferContextKey, [
    await transferLimitsModule.MAX_TRANSFERS_PER_PERIOD_TOPIC(),
  ]);
  await transferLimitsModule.addHandlerTopics(transferFromContextKey, [
    await transferLimitsModule.MAX_TRANSFERS_PER_PERIOD_TOPIC(),
  ]);

  return transferLimitsModule;
}

async function setupRarimoModule(deployer: Deployer, nftF: LandNFT): Promise<[EquityRarimoModule, RarimoSBT]> {
  const rarimoSBT = await deployer.deploy(RarimoSBT__factory);
  await rarimoSBT.__RarimoSBT_init();

  const rarimoModule = await deployer.deploy(EquityRarimoModule__factory);
  await rarimoModule.__EquityRarimoModule_init(nftF, rarimoSBT);

  const transferContextKey = await rarimoModule.getContextKey(await nftF.TRANSFER_SELECTOR());
  const transferFromContextKey = await rarimoModule.getContextKey(await nftF.TRANSFER_FROM_SELECTOR());

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
  const [nftF, kycCompliance, regulatoryCompliance] = await setupCoreContracts(deployer);

  const [rarimoModule, rarimoSBT] = await setupRarimoModule(deployer, nftF);
  const transferLimitsModule = await setupTransferLimitsModule(deployer, nftF);

  await kycCompliance.addKYCModules([rarimoModule]);
  await regulatoryCompliance.addRegulatoryModules([transferLimitsModule]);

  Reporter.reportContracts(
    ["LandNFT", await nftF.getAddress()],
    ["ERC20TransferLimitsModule", await transferLimitsModule.getAddress()],
    ["RarimoModule", await rarimoModule.getAddress()],
    ["RarimoSBT", await rarimoSBT.getAddress()],
  );
};
