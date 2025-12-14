# Consensus, Key, and Security Concepts

## Consensus Basics
- **Baking (block production):** Bakers propose blocks when they hold a baking right for a specific level/round. Time between rounds shrinks as rounds increase; missing a right causes delay and lost rewards.
- **Endorsing/attesting:** Endorsers include attestations that secure the previous block. Missing endorsements reduces rewards and can weaken chain fitness.
- **Finality intuition:** A block with 2/3+ endorsements and several confirmations is considered safe for operational purposes; wait for 2–3 blocks before reacting to chain head changes.
- **Reorg awareness:** Short reorgs happen; keep head lag under two blocks and avoid manual intervention unless lag persists.

## Slashing & Risky Actions
- **Double baking/endorsing:** Signing two competing blocks/endorsements for the same level/round leads to slashing and loss of security deposit.
- **Private key leakage:** Anyone with baking/endorsement keys can cause double-signing; hardware signers reduce this risk.
- **Timestamp/clock drift:** Large drift can invalidate rights; keep NTP active on hosts.

## Operational Expectations
- Track upcoming rights using `tezos-client show baking rights` and Grafana panels; ensure signer reachability before each cycle.
- Keep peer count healthy (>=10) to receive rights promptly; low peers increase head lag.
- Monitor mempool and fees during congestion; rights may expire if operations are not injected in time.

## Security & Access Controls
- **Principle:** Isolate signing from node operations. Operators should not handle private keys directly on servers.
- **Roles:**
  - *Ops*: manage nodes/monitoring, rotate snapshots, view logs.
  - *Key custodian*: controls hardware wallet, approves signing on remote signer.
  - *Auditor*: read-only access to monitoring/log archives.
- **Access:** SSH key-based auth only; sudo limited to the ops group; RPC exposed only to whitelisted admin subnet or via mTLS.

## Key Management Approach
- **Signer:** Hardware wallet (Ledger) connected to a dedicated remote signer host; Octez node uses `http://remote-signer:6732`.
- **Backup/restore:**
  - No mnemonic storage on servers. Ledger recovery phrase kept in a fireproof safe with access log.
  - Remote signer configs and authorization lists backed up weekly (encrypted) to offsite storage; test restore quarterly on Ghostnet with spare hardware.
  - If signer fails, switch to pre-staged backup signer after revoking old authorization; document event in incident log.
- **Operations without keys:** Node snapshots, monitoring, and log collection do not require key material and can be performed by ops with minimal privileges.

## Incident Readiness
- Define clear escalation: head lag >20 blocks for 5 minutes, repeated signer failures, or missed rights triggers paging.
- Run disaster-recovery drill quarterly: rebuild a node from snapshot, pair with backup signer on Ghostnet, and bake/endorse a right to validate readiness.
