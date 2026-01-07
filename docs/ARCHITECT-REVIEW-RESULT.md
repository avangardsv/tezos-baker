# Tezos Baker Architecture Review Result

Date: 2026-01-06

This document captures the architecture review output and the recommended next steps.

## 1. Architecture & Design

Rating: 4/5

What's Good
- Clear separation of node vs baker containers with shared data volume and container networking (`package.json:13`, `package.json:22`).
- Bootstrap peers are explicit for Ghostnet (`data/config.json:10`).

What's Bad
- Two orchestration paths (npm `docker run` vs `podman-compose`) can drift and confuse which is canonical (`package.json:13`, `podman-compose.yml:15`).
- Custom `Dockerfile` exists but isn't referenced anywhere (`Dockerfile:1`).

What's Simple
- Single-node, single-baker topology is easy to reason about for study mode (`README.md:16`).

What's Hard
- Config precedence is unclear across `.env`, `data/config.json`, and CLI flags (`README.md:264`, `data/config.json:3`, `package.json:13`).

Critical Issues
- None for testnet study mode.

Recommendations
- High: Pick a primary orchestration path (npm+docker or compose) and align docs/scripts to it.
- Medium: Document config precedence and overrides.

## 2. Code Quality & Scripts

Rating: 3/5

What's Good
- Scripts are short, readable, and handle log backup on stop (`scripts/node-stop.sh:1`, `scripts/baker-stop.sh:1`).

What's Bad
- Dependencies (`bc`, `jq`, `wget`) are assumed but never checked or documented (`scripts/stake-funds.sh:47`, `scripts/stake-status.sh:64`, `package.json:11`).

What's Simple
- Direct `docker exec` usage avoids extra wrappers (`package.json:16`).

What's Hard
- Script references to commands that don't exist create dead-ends (`scripts/stake-status.sh:81`, `scripts/stake-funds.sh:120`).
- `common.sh` isn't used by scripts that duplicate env loading (`scripts/lib/common.sh:8`, `scripts/stake-status.sh:7`).

Critical Issues
- Missing commands in UX flows are a functional break.

Recommendations
- High: Add missing npm scripts or remove references to them.
- Medium: Add host dependency checks or vendor them into a containerized helper.
- Low: Use `scripts/lib/common.sh` to avoid duplicated env loading.

## 3. Configuration Management

Rating: 3/5

What's Good
- `.env.example` is thorough and annotated for learners (`.env.example:1`).

What's Bad
- Many `.env` settings are never wired into scripts/compose (`.env.example:46`, `package.json:13`, `podman-compose.yml:15`).
- README says "All settings are in .env" even though `data/config.json` is also authoritative (`README.md:264`, `data/config.json:3`).

What's Simple
- Defaults in scripts reduce setup friction (`package.json:13`).

What's Hard
- Configuration split across `.env`, `data/config.json`, and compose with no "source of truth".

Critical Issues
- None for testnet.

Recommendations
- High: Either generate `data/config.json` from `.env` or document explicit override rules.
- Medium: Remove unused `.env` knobs or wire them into `package.json`/compose.
- Low: Remove or implement the referenced `npm run validate:production` (`.env.example:127`).

## 4. Operational Excellence

Rating: 3/5

What's Good
- Snapshot workflow is explicit and highlighted as mandatory for rolling mode (`README.md:14`, `package.json:11`).

What's Bad
- No verification that the node is bootstrapped before account creation or baker start (`package.json:16`, `package.json:22`).

What's Simple
- Stop scripts create log backups (`scripts/node-stop.sh:1`, `scripts/baker-stop.sh:1`).

What's Hard
- Snapshot download has no integrity check or size verification (`package.json:11`).

Critical Issues
- For production, missing key backup/restore steps are a must-fix.

Recommendations
- High: Add a `node:status` script that gates account/baker commands on bootstrapped state.
- Medium: Add snapshot integrity checks or recommend trusted verified snapshot sources.
- Low: Document explicit wallet backup/restore steps.

## 5. Documentation Quality

Rating: 4/5

What's Good
- README is clear, step-by-step, and warns about required staking and snapshots (`README.md:14`, `README.md:58`).

What's Bad
- Docs claim monitoring is removed while it still exists and is documented elsewhere (`docs/README.md:311`, `monitoring/README.md:1`).
- README references a production guide that doesn't exist (`README.md:298`).

What's Simple
- Quick start and health check are concise and actionable (`README.md:16`, `README.md:91`).

What's Hard
- Multiple READMEs and archived docs create navigation overhead (`docs/README.md:1`, `docs/archive/`).

Critical Issues
- Inaccurate documentation will mislead users.

Recommendations
- High: Fix stale references (monitoring "removed", missing production guide).
- Medium: Add a single "Start Here" doc that points to the canonical workflow.

## 6. Security Posture

Rating: 2/5 (appropriate for testnet, insufficient for mainnet)

What's Good
- Testnet framing is explicit; warnings about deleting data exist (`README.md:252`).

What's Bad
- RPC and metrics are bound to all interfaces, with no ACL by default (`package.json:13`, `data/config.json:4`).
- Grafana default credentials are documented in plaintext (`monitoring/README.md:18`, `docs/README.md:225`).

What's Simple
- Default open RPC makes local learning frictionless.

What's Hard
- No guidance for key management (Ledger/HSM), remote signer, or filesystem hardening.

Critical Issues
- Open RPC/metrics with no ACL is a must-fix before mainnet.

Recommendations
- High: Disable RPC exposure by default for mainnet or require ACL config.
- High: Remove default Grafana creds or require overrides in `.env`.
- Medium: Document hardware signer/remote signer options and key storage expectations.

## 7. Monitoring & Observability

Rating: 3/5

What's Good
- Metrics port is enabled and health checks are documented (`package.json:13`, `README.md:91`).

What's Bad
- No alerting or log rotation in the default npm workflow; rotation only in compose (`package.json:13`, `podman-compose.yml:24`).

What's Simple
- Curl-based quick checks make debugging easy (`README.md:95`, `docs/README.md:125`).

What's Hard
- Monitoring guidance is split between "archived" and active paths.

Critical Issues
- None for testnet; for production, alerting and log retention are required.

Recommendations
- Medium: Clarify monitoring path; keep curl checks and optional stack consistent.
- Low: Add a minimal alerting recommendation for mainnet readiness.

## 8. Testnet vs Mainnet Readiness

Rating: 2/5

What's Good
- Study mode framing and cost expectations are clear (`README.md:287`).

What's Bad
- Protocol-specific baker binary requires manual updates; no upgrade guidance (`package.json:22`, `podman-compose.yml:45`).

What's Simple
- Minimal infrastructure is perfect for Ghostnet learning (`README.md:289`).

What's Hard
- No explicit migration checklist from testnet to mainnet in active docs (`README.md:298`).

Critical Issues
- Key management, RPC exposure, monitoring/alerting, and HA are blockers for production.

Recommendations
- High: Add a "Mainnet Readiness Checklist" in active docs or link to an existing doc that exists.
- Medium: Add guidance on protocol upgrades and how to update `PROTOCOL` safely.

## 9. User Experience

Rating: 3/5

What's Good
- Quick start and help script are beginner-friendly (`README.md:12`, `scripts/help.sh:1`).

What's Bad
- CLI suggests commands that don't exist (stake:minimum, stake:custom, baker:rights, validate:production) (`scripts/stake-status.sh:81`, `scripts/stake-funds.sh:120`, `.env.example:127`).

What's Simple
- "15 essential commands" framing reduces cognitive load (`scripts/help.sh:47`).

What's Hard
- Beginners may hit "node not running" errors because scripts don't check container state before `docker exec` (`package.json:16`).

Critical Issues
- Missing commands are a UX blocker and damage trust.

Recommendations
- High: Add missing scripts or remove references across scripts/docs.
- Medium: Add pre-flight checks for Docker/container state in scripts.

## 10. Best Practices & Standards

Rating: 3/5

What's Good
- Uses official images and standard Octez commands (`package.json:8`, `package.json:13`).

What's Bad
- `wget` snapshot download without verification is not best practice (`package.json:11`).
- ACL/security guidance is optional rather than default (`README.md:133`, `data/config.json:3`).

What's Simple
- Lean `docker run` workflow matches learning goals (`README.md:16`).

What's Hard
- Lack of standardized config templating makes it easy to diverge from Octez best practices.

Critical Issues
- For mainnet, lack of hardening guidance and key management is a standards gap.

Recommendations
- High: Add snapshot verification guidance (hash or signed source).
- Medium: Provide a hardened `data/config.json` template for mainnet.

## Final Summary

Overall Assessment: 3.5/5 for study mode; strong learning experience, but production readiness is far below acceptable.

Top 3 Strengths
- Clear onboarding flow (`README.md:12`).
- Explicit staking guidance (`README.md:58`).
- Simple command surface (`scripts/help.sh:1`).

Top 3 Weaknesses
- Doc drift and missing commands (`docs/README.md:311`, `scripts/stake-status.sh:81`).
- Open RPC/metrics without ACL (`data/config.json:4`, `package.json:13`).
- Configuration spread across multiple sources without clear precedence (`README.md:264`).

Blockers for Production
- RPC exposure/ACL, key management, alerting/monitoring, protocol upgrade process.

Quick Wins
- Fix doc inconsistencies and missing scripts.
- Add dependency checks for `bc`, `jq`, `wget`.

Long-term Improvements
- Consolidate configuration, add hardened mainnet profile, build an upgrade/ops playbook.

## Next Steps

1) Add the missing npm scripts or remove their mentions from scripts/docs.
2) Add a "Mainnet Readiness Checklist" doc and link it from `README.md`.
3) Add a minimal `node:status` script that checks bootstrapped + container state.
