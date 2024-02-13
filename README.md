# Hardhat template 

Template hardhat repository for ad-hoc smart contracts development.

### How to use

The template works out of the box. To clean up the repo, you may need to delete the mock contracts, tests and migration files.

#### Compilation

To compile the contracts, use the next script:

```bash
npm run compile
```

#### Test

To run the tests, execute the following command:

```bash
npm run test
```

Or to see the coverage, run:

```bash
npm run coverage
```

#### Local deployment

To deploy the contracts locally, run the following commands (in the different terminals):

```bash
npm run private-network
npm run deploy-localhost
```

#### Bindings

The command to generate the bindings is as follows:

```bash
npm run generate-types
```

> See the full list of available commands in the `package.json` file.

### Integrated plugins

- Hardhat official `ethers` + `ethers-v6`
- [`Typechain`](https://www.npmjs.com/package/@typechain/hardhat)
- [`hardhat-migrate`](https://www.npmjs.com/package/@solarity/hardhat-migrate), [`hardhat-markup`](https://www.npmjs.com/package/@solarity/hardhat-markup), [`hardhat-gobind`](https://www.npmjs.com/package/@solarity/hardhat-gobind)
- [`hardhat-contract-sizer`](https://www.npmjs.com/package/hardhat-contract-sizer)
- [`hardhat-gas-reporter`](https://www.npmjs.com/package/hardhat-gas-reporter)
- [`solidity-coverage`](https://www.npmjs.com/package/solidity-coverage)

### Other niceties

- The template comes with presetup `prettier` and `solhint` that lint the project via `husky` before compilation hook.
- The `.env.example` file is provided to check what is required as ENVs
- Preinstalled `@openzeppelin/contracts` and `@solarity/solidity-lib`
