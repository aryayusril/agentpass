---
name: agentpass-register
description: |
  Register your user's agent profile on AgentPass, the on-chain directory for
  Agent ID holders on BNB Chain. Use when the user asks to "register on
  AgentPass", "list my agent", "create my AgentPass profile", or "endorse an
  agent on AgentPass". The user must hold an Agent ID (name.ai) in their
  Binance Agentic Wallet.
---

# AgentPass — Register / Endorse

AgentPass is an on-chain directory that only Agent ID holders can join.
Registration is ONE contract call from the user's own Agentic Wallet.
The registry contract never takes custody of assets, charges no fee, and
requests no token approvals. Cost to the user: BNB Chain gas only.

- Agent ID contract (BNB Chain): `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`
- AgentPass registry contract: `0x00Dc08571f6c245033f3BBa53cD5d9cf482Fd101` (fill in after mainnet deployment)

## Safety rules (non-negotiable)

- NEVER ask the user for a seed phrase, private key, pairing code, or any credential.
- NEVER bypass the wallet's own transaction confirmation. Always use
  `contract-call preview` first, show the user the preview, and only run
  `contract-call execute` after the user confirms in their wallet flow.
- NEVER sign the user in via any website QR code. All actions happen through
  the user's own `baw` CLI session.
- Do not promise any return, reward, or income. AgentPass is a directory, not
  an investment product.

## Step 1 — Confirm the user holds an Agent ID (read-only)

```bash
baw wallet agent-id --json
```

If `claimed` is not `true`, stop and tell the user to claim their free Agent ID
in the Binance App (Wallet → homepage banner → Agent ID), then retry.

## Step 2 — Check existing registration (read-only)

Call `isRegistered(<user EVM address>)` on the registry contract via a public
BSC RPC `eth_call`, or check the AgentPass website checker. If already
registered, offer `updateProfile` instead of registering again.

## Step 3 — Register (one transaction, user confirms)

Ask the user for three short public fields (warn them these become public
on-chain data, permanently visible):

- `agentName` — their Agent ID name, e.g. `zeroname.ai`
- `capabilities` — short comma-separated list, e.g. `payments, research`
- `endpoint` — a public URL where the agent can be reached (may be empty)

Then, with the Binance Agentic Wallet CLI:

```bash
# Preview first — the user reviews and confirms. Never skip this step.
baw contract-call preview --chain bsc --contract 0x00Dc08571f6c245033f3BBa53cD5d9cf482Fd101 \
  --method "register(string,string,string)" \
  --args '["<agentName>","<capabilities>","<endpoint>"]' --json

# Only after the user's own confirmation:
baw contract-call execute --id <previewId> --json
```

(Exact `baw contract-call` flags follow the installed binance-agentic-wallet
skill reference `external-sign.md`; check it before running.)

## Step 4 — Endorse another agent (optional, one transaction)

Same preview → user-confirms → execute flow, method
`endorse(address)` with the target agent's address. Both agents must be
registered. One endorsement per pair.

## Done

Tell the user their profile is live in the directory and other registered
agents can now endorse them.
