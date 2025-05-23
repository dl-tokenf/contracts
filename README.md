[![npm](https://img.shields.io/npm/v/@tokenf/contracts.svg)](https://www.npmjs.com/package/@tokenf/contracts)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# TokenF - RWA Tokenization Framework

Bring Real World Assets (RWA) on-chain via flexible tokenization framework - TokenF.

TokenF and NFTF architecture:

!["AssetF Architecture"](https://github.com/user-attachments/assets/5c934752-9f37-477e-8ae8-f1f6dfb001bd)

Built with [Solarity](https://github.com/dl-solarity), [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts), and aspiration to perfection.

## Application

TokenF is an on-chain framework that enables development, management, and deployment of permissioned ERC-20-compatible and ERC-721-compatible assets on EVM networks. TokenF enables custom rules to be configured for RWA tokens, providing flexible KYC/AML and regulatory compliance checks for the users to abide during interaction with the smart contracts.

TokenF is built with certain levels of abstraction in mind:

- ERC-2535 Diamond beating heart that allows extensibility and upgradeability.
- Support of custom compliance modules to be plugged in the TokenF core.
- Rich configuration of check/hooks/behavior with imagination being the only limit.

| **What TokenF Is ✅**                        | **What TokenF Is Not ❌**           |
| :-----------------------------------------:  | :---------------------------------: |
| On-chain tokenization framework              | Fullstack tokenization framework    |
| Smart contracts to configure RWA behavior    | RWA launchpad/RWA consulting set    |
| Built from scratch ERC-3643 alternative      | Yet another ERC-3643 copy           |
| Support of both ERC-20 and ERC-721 standards | Currently does not support ERC-1155 |

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
pragma solidity ^0.8.21;

import {TokenF} from "@tokenf/contracts/TokenF.sol";
import {NFTF} from "@tokenf/contracts/NFTF.sol";

contract EquityToken is TokenF {
    . . .
}

// or

contract LandNft is NFTF {
    . . .
}
```

> [!TIP]
> Check out the `examples` directory to learn how to bring your RWA on-chain!

There is an abundant [documentation](https://tokenf.gitbook.io/tokenf) available for the framework. If you are planning to build with TokenF, do check it out!

## Contribution

With an ambitious goal to make RWA simple, we are open to any mind-blowing improvement proposals.

## License

The framework is released under the MIT License.
