import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import {
  EquityKYCCompliance,
  EquityKYCCompliance__factory,
  EquityNFT,
  EquityNFT__factory,
  EquityRarimoModule,
  EquityRarimoModule__factory,
  EquityRegulatoryCompliance__factory,
  RarimoSBT,
  RarimoSBT__factory,
} from "@ethers-v6";

async function setupCoreContracts(deployer: Deployer): Promise<[EquityNFT, EquityKYCCompliance]> {
  const nftF = await deployer.deploy(EquityNFT__factory);
  const kycCompliance = await deployer.deploy(EquityKYCCompliance__factory);
  const regulatoryCompliance = await deployer.deploy(EquityRegulatoryCompliance__factory);

  const regulatoryComplianceInitData = regulatoryCompliance.interface.encodeFunctionData(
    "__EquityRegulatoryCompliance_init",
  );
  const kycComplianceInitData = kycCompliance.interface.encodeFunctionData("__EquityKYCCompliance_init");

  await nftF.__EquityNFT_init(regulatoryCompliance, kycCompliance, regulatoryComplianceInitData, kycComplianceInitData);

  return [nftF, kycCompliance.attach(nftF) as EquityKYCCompliance];
}

async function setupRarimoModule(deployer: Deployer, nftF: EquityNFT): Promise<[EquityRarimoModule, RarimoSBT]> {
  const rarimoSBT = await deployer.deploy(RarimoSBT__factory);
  await rarimoSBT.__RarimoSBT_init();

  const rarimoModule = await deployer.deploy(EquityRarimoModule__factory);
  await rarimoModule.__EquityRarimoModule_init(nftF, rarimoSBT);

  const transferContextKey = await rarimoModule.getContextKey(await nftF.TRANSFER_SELECTOR());
  const transferFromContextKey = await rarimoModule.getContextKey(await nftF.TRANSFER_FROM_SELECTOR());

  await rarimoModule.addHandleTopics(transferContextKey, [
    await rarimoModule.HAS_SOUL_SENDER_TOPIC(),
    await rarimoModule.HAS_SOUL_RECIPIENT_TOPIC(),
  ]);
  await rarimoModule.addHandleTopics(transferFromContextKey, [
    await rarimoModule.HAS_SOUL_SENDER_TOPIC(),
    await rarimoModule.HAS_SOUL_RECIPIENT_TOPIC(),
    await rarimoModule.HAS_SOUL_OPERATOR_TOPIC(),
  ]);

  return [rarimoModule, rarimoSBT];
}

export = async (deployer: Deployer) => {
  const [nftF, kycCompliance] = await setupCoreContracts(deployer);

  const [rarimoModule, rarimoSBT] = await setupRarimoModule(deployer, nftF);

  await kycCompliance.addKYCModules([rarimoModule]);

  Reporter.reportContracts(
    ["EquityNFT", await nftF.getAddress()],
    ["RarimoModule", await rarimoModule.getAddress()],
    ["RarimoSBT", await rarimoSBT.getAddress()],
  );
};
