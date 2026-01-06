# Codex Complexity Analysis & Simplification Plan

## Current State (vs. Octez / OpenTezos guides)
- Many npm/bash wrappers; official guides rely on direct `octez-node` / `octez-client` calls.
- Monitoring stack is heavy by default (Prom+Grafana+Loki+Promtail+node_exporter) vs. Octez’s Prometheus-only guidance.
- Documentation and scripts contain verbose, educational flows and multiple paths.
- Dashboards include mixed datasources and placeholder `<chain_id>` strings.

## Minimal Target (aligned to Octez/OpenTezos)
- Scripts: keep ~12–15 essentials; archive the rest.
  - Setup: `setup`, `snapshot:download`, `snapshot:import`
  - Node: `node:start`, `node:stop`, `node:logs`
  - Account/Delegate: `account:create`, `account:show`, `account:balance`, `delegate:register`, `delegate:status`
  - Baker: `baker:start`, `baker:stop`, `baker:logs`, `baker:status`
  - Monitor: `monitor` (one script)
  - Staking: keep at most `stake:all`, `stake:minimum`, `stake:status`
  - Remove/Archive: node:* variants (status/head/peers/chain-id/restart/bootstrap), block:inspect, security:configure-acl helper (document ACL inline), multiple monitor variants, interactive/verbose staking menus.
- Monitoring: default to Prometheus + Grafana only; make Loki/Promtail/node_exporter optional (separate compose or profile).
- Dashboards: one lean dashboard with head level, head lag, bootstrapped, peers, validation errors (rate), invalid blocks, baker up (if scraped), and optional CPU/mem if node_exporter enabled. Remove mixed datasources and placeholder `<chain_id>`; set the real Prometheus UID and ghostnet chain_id.
- Config: single `data/config.json` template; rolling ghostnet, peers, RPC bind 127.0.0.1:8732 by default, ACL snippet documented in README.
- Docs: concise README matching Octez/OpenTezos flow: prereqs → snapshot import → identity → run → account → fund → delegate → stake → baker → verify; troubleshoot insufficient history and ACL filtering.
- Environment: minimal `.env` (network ghostnet, rolling, RPC_ADDR=127.0.0.1, ports, baker alias). Avoid extra toggles.

## Concrete Simplifications
1) Trim `package.json` scripts to the essential set; move unused scripts to `scripts/archive/`.
2) Remove default Loki/Promtail/node_exporter from monitoring compose; provide optional override for them.
3) Replace dashboards with a lean JSON using the real Prometheus UID and ghostnet chain_id; drop mixed datasources/placeholders.
4) Update README/help to reference raw `octez-*` commands alongside wrappers; remove verbose educational text from scripts.
5) Keep staking helpers minimal (all/min/status) and non-interactive by default; document plain `octez-client stake/unstake` commands.
6) Remove unused jb/jsonnet tooling unless actively used to manage dashboards.
