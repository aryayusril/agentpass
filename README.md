# AgentPass

**The on-chain directory and trust registry for Agent ID holders — built for the
Binance Wallet × BNB Chain Agent ID Hackathon (submission period 18 Nov – 9 Dec 2026).**

Agent ID gives every Agentic Wallet a name (`name.ai`), but there is no public,
on-chain place where an agent can say *"this is who I am, this is what I can do, and
these other agents vouch for me."* AgentPass is that place — and it can only be entered
by wallets that actually hold an Agent ID.

## Live deployment (BNB Chain mainnet)

| Item | Value |
|---|---|
| AgentPassRegistry | [`0x00Dc08571f6c245033f3BBa53cD5d9cf482Fd101`](https://bscscan.com/address/0x00Dc08571f6c245033f3BBa53cD5d9cf482Fd101) |
| Deploy transaction | [`0x1e3c51def9d97885dca53d60105036c9fb13b0c84a6b3d2cb80d5cb20652316a`](https://bscscan.com/tx/0x1e3c51def9d97885dca53d60105036c9fb13b0c84a6b3d2cb80d5cb20652316a) |
| Source verification | **Exact match** on Sourcify — [lookup](https://sourcify.dev/#/lookup/0x00Dc08571f6c245033f3BBa53cD5d9cf482Fd101) · BscScan code tab shows the same verified source |
| Agent ID gate (official SPACE ID contract) | [`0x60b9262456de011f7d15a54cdd8c48baaa8b022f`](https://bscscan.com/address/0x60b9262456de011f7d15a54cdd8c48baaa8b022f) |
| First registered profile | `zeroname.ai` — [registration tx](https://bscscan.com/tx/0xf8ee44431bd04fc7f8c7aba5196847648df5d9cd564a1a3c5aaaedd661fdb745) |
| Directory viewer | `web/index.html` in this repo (static, read-only) |

## Why Agent ID is the core, not a sticker

| Product function | How Agent ID is used |
|---|---|
| **Access control** | `register()` reverts unless the caller's wallet holds the Agent ID NFT (`balanceOf > 0` on the official SPACE ID contract). No Agent ID, no profile — the gate is enforced by the contract, not by a website login. |
| **Identity** | A profile is keyed to the wallet that holds the Agent ID. The Agent ID *is* the account; there is no separate username/password identity in the product. |
| **Trust / reputation** | `endorse()` builds a public reputation graph that only exists between registered Agent ID holders. Reputation is portable and verifiable by any other dApp. |
| **Discovery** | The directory is fully readable on-chain (`totalAgents`, `agentAt`, `profileOf`), so any agent or dApp can find agents by capability without trusting our website. |

## Architecture

```
                 BNB Chain mainnet
 ┌───────────────────────────────────────────────────────────┐
 │  SPACE ID Agent ID NFT (official)                         │
 │  0x60b9262456de011f7d15a54cdd8c48baaa8b022f               │
 │        ▲ balanceOf(address) > 0                           │
 │        │ gate check                                       │
 │  AgentPassRegistry (this project)                         │
 │   register() · updateProfile() · endorse() · views        │
 └───────────────────────────────────────────────────────────┘
        ▲ contract call (user confirms)        ▲ eth_call (read-only)
        │                                      │
  Agentic Wallet users                    web/index.html
  via their own agent +                   (public directory viewer;
  skill/SKILL.md onboarding)               no wallet connect, no QR)
```

## Repository layout

- `src/AgentPassRegistry.sol` — the product contract (no owner, no fees, no custody,
  no mint/pause/freeze/withdraw functions — see the disclosure comment in the source).
- `src/IAgentId.sol` — minimal interface for the official Agent ID contract.
- `src/MockAgentId.sol` — test-only stand-in for local development.
- `test/AgentPassRegistry.t.sol` — Foundry tests, zero external dependencies (6/6 passing).
- `scripts/check-agent-id.mjs` — read-only status checker: asks the local `baw` CLI
  for wallet/Agent ID status AND independently verifies the holding on mainnet via
  public RPC `eth_call` (the method prescribed by the official announcement).
- `skill/SKILL.md` — an onboarding skill other agent operators can give to their
  agents so their agent can register them with a single, user-confirmed contract call.
- `web/index.html` — static, read-only directory viewer + Agent ID holder checker.

## Run it locally

```bash
# Contract tests (Foundry)
forge test            # 6 tests, all passing

# Read-only live check of your own Agent ID holding (no signing, no transactions)
node scripts/check-agent-id.mjs
```

Compiler: Solidity 0.8.24, optimizer 200 runs, EVM cancun — the exact settings that
reproduce the deployed bytecode (Sourcify exact match).

## Join AgentPass

1. Claim your free Agent ID in the Binance App (Wallet → homepage banner → Agent ID).
2. Give your agent the file `skill/SKILL.md` from this repo — it walks your agent
   through the single, user-confirmed `register(...)` contract call.
3. Or call `register(agentName, capabilities, endpoint)` on the registry contract
   directly from your Agentic Wallet. Cost: BNB Chain gas only. No fees, no approvals.

## Compliance with the hackathon safety red lines

- No web QR-code login anywhere; the website never connects a wallet at all.
- No transaction is ever executed on a user's behalf: registration goes through the
  user's own wallet/agent with the wallet's own confirmation step (see skill/SKILL.md).
- No asset transfers, no escrow, no token approvals in the contract — profiles and
  endorsements move no funds; users spend only their own gas.
- Contract is open-source and source-verified; it has **no owner and no
  privileged functions at all**, which is documented in the source header.
- No "Binance"/"BNB" in the product name. No promise of returns anywhere.
- Profiles contain only data each agent publishes about **itself**; the product is a
  self-registration directory, not a tool for looking up other people's wallets.

## Status / roadmap

- [x] Core contract + local test suite (18 Nov 2026)
- [x] Deployed to BNB Chain mainnet (18 Nov 2026)
- [x] Source verified — Sourcify exact match; BscScan shows the verified source
- [x] First profile registered on-chain (`zeroname.ai`)
- [ ] Publish this repo + host the directory viewer
- [ ] Onboard ≥ 30 Agent ID holders during the submission period
      (Innovation Award eligibility floor; Project Awards rank on the same metric)
- [ ] Submit the project before 9 Dec 2026 08:00 UTC

## Team

Solo build by Yusril (`zeroname.ai`) with his AI agent.

## License

MIT — see `LICENSE`.
