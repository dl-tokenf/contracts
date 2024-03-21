[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# TokenF - Tokenize Finance

Bring Real World Assets (RWA) on-chain via flexible tokenization framework - TokenF.

## Application

TokenF is an on-chain framework that enables development, management, and deployment of permissioned ERC20-compatible assets on EVM networks. TokenF enables custom rules to be configured for RWA tokens, providing flexible KYC/AML and regulatory compliance checks for the users to abide during interaction with the smart contracts.

TokenF is built with certain levels of abstraction in mind: 

- ERC2535 Diamond beating heart that allows extensibility and upgradeability.
- Support of custom compliance modules to be plugged in the TokenF core.
- Rich configuration of check/hooks/behavior with imagination being the only limit.

| **What TokenF Is ✅**                       | **What TokenF Is Not ❌**        |
| :-----------------------------------------: | :------------------------------: |
| On-chain tokenization framework             | Fullstack tokenization framework |
| Smart contracts to configure RWA behavior   | RWA launchpad/RWA consulting set |
| Reimagined and enhanced ERC3643 alternative | Yet another ERC3643 copy         |

> [!NOTE]
> TokenF is at the early stage of development, many breaking changes are foreseen.

## Usage

TokenF is an open-source product with no limitation for the usage (MIT license)!

The framework is available as an NPM package:

```bash
npm install @tokenf/contracts
```

You will then be able to start using TokenF:

```solidity
pragma solidity ^0.8.20;

import {TokenF} from "@tokenf/contracts/core/TokenF.sol";

contract EquityToken is TokenF {
    . . .
}
```

> [!TIP]
> Check out the `examples` directory to learn how to bring your RWA on-chain!

There is an abundant [documentation]() available for the framework. If you are planning to build with TokenF, do check it out!

## Contribution

With an ambitios goal to make RWA simple, we are open to any mind-blowing improvement proposals.

## License

The library is released under the MIT License.
