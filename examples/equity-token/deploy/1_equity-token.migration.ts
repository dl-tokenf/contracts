import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import { EquityToken__factory } from "../generated-types/ethers";

export = async (deployer: Deployer) => {
  const token = await deployer.deploy(EquityToken__factory);

  Reporter.reportContracts(["EquityToken", await token.getAddress()]);
};
