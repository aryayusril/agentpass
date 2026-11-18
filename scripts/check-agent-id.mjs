#!/usr/bin/env node
/**
 * Read-only status check for the Agent ID Hackathon build.
 *
 * Does two independent READ-ONLY checks (no signing, no transactions):
 *  1. Asks the local Binance Agentic Wallet CLI (`baw`) for connection status
 *     and our own Agent ID claim status.
 *  2. Verifies the holding directly on BNB Chain mainnet via a public RPC
 *     `eth_call balanceOf(address)` against the official SPACE ID Agent ID
 *     contract — the exact method the official announcement prescribes.
 *
 * Usage: node scripts/check-agent-id.mjs [address]
 * Default address: Yusril's Agentic Wallet EVM address.
 */

import { execFileSync } from "node:child_process";

const BAW = process.env.BAW_PATH || "baw";
const AGENT_ID_CONTRACT = "0x60b9262456de011f7d15a54cdd8c48baaa8b022f"; // SPACE ID Agent ID (BNB Chain)
const BSC_RPC = process.env.BSC_RPC || "https://bsc-dataseed.binance.org";
const DEFAULT_ADDRESS = "0xE30E1f15bBc0D1aE874124aC6c85c56a84200b58";

const address = (process.argv[2] || DEFAULT_ADDRESS).toLowerCase();

function runBaw(args) {
  try {
    const out = execFileSync(BAW, [...args, "--json"], { encoding: "utf8", timeout: 30_000 });
    return JSON.parse(out);
  } catch (err) {
    return { error: String(err.message || err).slice(0, 200) };
  }
}

async function balanceOfOnChain(addr) {
  // eth_call balanceOf(address): selector 0x70a08231 + 32-byte padded address
  const data = "0x70a08231" + addr.replace(/^0x/, "").padStart(64, "0");
  const res = await fetch(BSC_RPC, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "eth_call",
      params: [{ to: AGENT_ID_CONTRACT, data }, "latest"],
    }),
  });
  const json = await res.json();
  if (json.error) throw new Error(JSON.stringify(json.error));
  return BigInt(json.result);
}

const status = runBaw(["wallet", "status"]);
const agentId = runBaw(["wallet", "agent-id"]);

let onChain = null;
try {
  const bal = await balanceOfOnChain(address);
  onChain = { contract: AGENT_ID_CONTRACT, address, balanceOf: bal.toString(), holdsAgentId: bal > 0n };
} catch (err) {
  onChain = { error: String(err.message || err).slice(0, 200) };
}

console.log(
  JSON.stringify(
    {
      bawWalletStatus: status?.data ?? status,
      bawAgentId: agentId?.data ?? agentId,
      onChainCheck: onChain,
    },
    null,
    2,
  ),
);
