# DeadSwitch

## Trustless digital inheritance on Ethereum

DeadSwitch is an educational blockchain application that demonstrates how
digital assets can be transferred to a nominated beneficiary without relying
on a bank, administrator, or custodial company.

The project implements a **dead man's switch** for ETH. The owner creates a
will, selects a beneficiary, deposits ETH, and chooses how often they must
check in. Every check-in resets the timer. If the owner stops checking in and
the configured interval expires, the beneficiary can submit a claim. The
smart contract validates the beneficiary and the timeout before releasing the
funds.

This project is intended for academic demonstration and testing. It is not a
legally valid will, financial product, or production custody solution.

## Project objectives

- Demonstrate how Solidity smart contracts can enforce inheritance rules.
- Remove the need for a central service to hold private keys or control funds.
- Show how time-based conditions can be implemented on Ethereum.
- Provide a simple browser interface for creating, managing, inspecting, and
  claiming a will.
- Make contract state and transaction results visible to the user.

## How the system works

1. **Create a will**
   The owner connects a wallet, enters a beneficiary address, selects a
   check-in interval, and deposits ETH. The contract stores these values on
   chain.

2. **Check in**
   The owner periodically sends a `checkIn` transaction. This updates the
   `lastCheckIn` timestamp and keeps the will active.

3. **Manage funds**
   While the will is active, the owner can deposit additional ETH or cancel
   the will and receive the balance back.

4. **Wait for the timeout**
   The contract compares the current blockchain timestamp with the last
   check-in plus the selected interval.

5. **Claim the inheritance**
   After the timeout, only the nominated beneficiary can call
   `claimInheritance`. The contract transfers the stored balance directly to
   the beneficiary's wallet.

The website cannot bypass these rules. Validation is performed by the
deployed contract, which means the same rules apply regardless of who submits
a transaction.

## Repository structure

| File | Purpose |
| --- | --- |
| [`deadSwitch.sol`](./deadSwitch.sol) | Solidity contract containing the will, timer, deposit, cancellation, and claim logic. |
| [`index.html`](./index.html) | Public landing page explaining the problem and the project idea. |
| [`how.html`](./how.html) | Plain-language explanation of the contract workflow. |
| [`manage.html`](./manage.html) | Browser interface for interacting with the contract through MetaMask. |
| [`artifacts/DeadSwitch.json`](./artifacts/DeadSwitch.json) | Compiled contract ABI and deployment metadata used by development tools. |
| [`remix.config.json`](./remix.config.json) | Remix workspace configuration. |

## Smart contract design

The contract stores one will per owner address:

```solidity
struct Will {
    address owner;
    address payable beneficiary;
    uint256 balance;
    uint256 lastCheckIn;
    uint256 checkInInterval;
    bool exists;
}
```

Important safeguards include:

- The beneficiary cannot be the zero address or the owner.
- A check-in interval must be at least 60 seconds.
- A will must contain a positive ETH balance when created.
- Only the will owner can deposit, check in, or cancel.
- Only the nominated beneficiary can claim.
- A claim is rejected until the check-in interval has elapsed.
- The balance and existence flag are cleared before a payout is sent.

The contract also emits events for creation, deposits, check-ins,
cancellations, and claims. These events make the application's activity
auditable through the blockchain.

## Running the project with Remix

### 1. Compile the contract

1. Open the project in [Remix IDE](https://remix.ethereum.org/).
2. Open `deadSwitch.sol`.
3. Select Solidity compiler version `0.8.20` or a compatible `0.8.x` version.
4. Compile `DeadSwitch`.

### 2. Deploy for testing

Use the **Deploy & Run Transactions** panel and select one of these options:

- **Remix VM** for local, disposable blockchain testing.
- **Injected Provider - MetaMask** for a test network or another network you
  explicitly control.

Use small test amounts. After deployment, copy the contract address into the
`CONTRACT_ADDRESS` constant near the top of the script in
[`manage.html`](./manage.html).

### 3. Open the application

Serve the project directory with any local static web server and open
`index.html` in a browser. For example, with Python installed:

```bash
python3 -m http.server 8000
```

Then visit <http://localhost:8000/>.

The management page requires MetaMask and must be connected to the same
network as the deployed contract.

## Technology stack

- **Solidity 0.8.20** for the smart contract.
- **Ethereum-compatible blockchain** for persistent contract state.
- **MetaMask** for wallet connection and transaction signing.
- **ethers.js 6.7.0** for browser-to-contract communication.
- **HTML and CSS** for the client interface.
- **Remix IDE** for compiling and deploying the contract.

The website never asks for or handles a seed phrase or private key. MetaMask
handles transaction signing in the user's wallet.

## Limitations and risks

DeadSwitch uses inactivity as a signal; it cannot prove that a person has
died. It cannot replace a legal will, verify identity, settle family
disputes, or guarantee recognition under local law.

The contract is a demonstration and has not been presented as a formally
audited production system. Blockchain transactions are generally irreversible
and may require gas fees. Users should review the source code, verify the
network and contract address, and test only with funds they can afford to
lose.

## Academic summary

DeadSwitch explores how blockchain programmability can replace a trusted
intermediary with transparent, deterministic rules. The project combines a
Solidity contract with a lightweight web interface to demonstrate a complete
decentralized application workflow: wallet authentication, transaction
submission, on-chain state updates, read-only contract queries, and
condition-based asset transfer.
