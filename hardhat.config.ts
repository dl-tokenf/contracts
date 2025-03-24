import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@solarity/hardhat-markup";
import "@typechain/hardhat";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "tsconfig-paths/register";

import { HardhatUserConfig } from "hardhat/config";

import * as dotenv from "dotenv";
dotenv.config();

function privateKey() {
  return process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [];
}

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      initialDate: "1970-01-01T00:00:00Z",
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      gasMultiplier: 1.2,
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: privateKey(),
      gasMultiplier: 1.2,
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: privateKey(),
      gasMultiplier: 1.2,
    },
    chapel: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      accounts: privateKey(),
      gasMultiplier: 1.2,
      timeout: 60000,
    },
    mumbai: {
      url: `https://rpc-mumbai.maticvigil.com/`,
      accounts: privateKey(),
      gasMultiplier: 1.2,
    },
    fuji: {
      url: `https://avalanche-fuji.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: privateKey(),
      gasMultiplier: 1.2,
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      accounts: privateKey(),
      gasMultiplier: 1.2,
    },
    ethereum: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: privateKey(),
      gasMultiplier: 1.2,
    },
    polygon: {
      url: `https://matic-mainnet.chainstacklabs.com`,
      accounts: privateKey(),
      gasMultiplier: 1.2,
    },
    avalanche: {
      url: `https://api.avax.network/ext/bc/C/rpc`,
      accounts: privateKey(),
      gasMultiplier: 1.2,
      timeout: 60000,
    },
  },
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "paris",
    },
  },
  mocha: {
    timeout: 1000000,
  },
  contractSizer: {
    alphaSort: false,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: false,
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 50,
    enabled: false,
    coinmarketcap: `${process.env.COINMARKETCAP_KEY}`,
  },
  typechain: {
    outDir: "generated-types/ethers",
    target: "ethers-v6",
    alwaysGenerateOverloads: true,
    discriminateTypes: true,
  },
};

export default config;
