# uocoin

uocoin is a fungible token implemented as a [Clarity](https://docs.stacks.co/write-smart-contracts/language-overview) smart contract and managed with [Clarinet](https://docs.hiro.so/clarinet/overview). This repository contains the on-chain contract code as well as a local development environment for building and testing the token.

## Project structure

- `Clarinet.toml` – Clarinet project configuration
- `contracts/` – Clarity smart contracts
  - `uocoin.clar` – uocoin fungible token implementation
- `settings/` – Clarinet network configuration (Devnet/Testnet/Mainnet)
- `tests/` – TypeScript tests for contracts (using `clarinet` + `vitest`)
- `.vscode/` – Example VS Code tasks and settings

## Prerequisites

- **Node.js** (LTS recommended)
- **Clarinet** – already initialized in this project

To verify Clarinet is available:

```bash
clarinet --version
```

## Getting started

Clone this repository and install dependencies:

```bash
git clone <your-repo-url> uocoin
cd uocoin
npm install
```

## Contract: `uocoin`

`uocoin.clar` defines a SIP-010-like fungible token with:

- Token name: `uocoin`
- Symbol: `UOC`
- Decimals: `6`
- Standard balance and allowance tracking using Clarity maps

### Public read-only functions

- `get-name` → `(response (string-utf8 40) uint)` – returns the token name
- `get-symbol` → `(response (string-utf8 16) uint)` – returns the token symbol
- `get-decimals` → `(response uint uint)` – returns the decimals used
- `get-total-supply` → `(response uint uint)` – returns the total minted supply
- `get-balance (who principal)` → `(response uint uint)` – returns `who`'s balance
- `get-allowance (owner principal) (spender principal)` → `(response uint uint)` – returns allowance for `spender` to spend from `owner`

### Public state-changing functions

- `mint (recipient principal) (amount uint)`
  - Mints `amount` tokens to `recipient`.
  - Only the contract deployer (owner) is authorized.
- `transfer (amount uint) (sender principal) (recipient principal)`
  - Transfers `amount` tokens from `sender` to `recipient`.
  - `sender` must match `tx-sender`.
- `transfer-from (amount uint) (owner principal) (recipient principal)`
  - Transfers using allowance from `owner` to `recipient`.
  - Caller must be an approved spender.
- `approve (spender principal) (amount uint)`
  - Sets or updates allowance for `spender` to spend tokens from the caller's balance.

### Error codes

- `u100` – not authorized
- `u101` – insufficient balance
- `u102` – insufficient allowance
- `u103` – invalid amount (zero)

## Running Clarinet checks

To type-check and validate all contracts:

```bash
clarinet check
```

This will compile all contracts under `contracts/` and report any syntax or type errors.

## Running tests

Clarinet scaffolds TypeScript tests under `tests/`. To run them:

```bash
npm test
```

You can add more tests in the `tests/` directory to cover your desired token behavior (minting, transfers, allowances, and failure cases).
