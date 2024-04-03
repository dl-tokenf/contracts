import "@nomicfoundation/hardhat-ethers";
import "@solarity/hardhat-migrate";
import "@typechain/hardhat";
import "tsconfig-paths/register";

import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      gasMultiplier: 1.2,
    },
  },
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "paris",
    },
  },
  migrate: {
    pathToMigrations: "./deploy/",
  },
  typechain: {
    outDir: "generated-types/ethers",
    target: "ethers-v6",
    alwaysGenerateOverloads: true,
    discriminateTypes: true,
  },
};

export default config;
