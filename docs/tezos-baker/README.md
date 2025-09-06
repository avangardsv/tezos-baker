# Tezos Baker — Operator Guide (Ghostnet → Mainnet)

## TL;DR
- Start on Ghostnet via Docker Compose. Verify sync with `tezos-client bootstrapped` and keep head lag <2.
- Register a test delegate, bake/endorse, wire up monitoring, run failure drills.
- When stable, repeat on Mainnet with hardened security and a hardware signer.

## Goals & Success
- Validate end-to-end baker ops on Ghostnet; create a repeatable path to Mainnet (6000 XTZ).
- Sustained full sync (<2 block lag for 24h), bake/endorse observed, alerts active, security baseline implemented.

## Repository Layout (planned)
```
tezos-baker/
  .env.example
  docker/ compose.ghostnet.yml, compose.mainnet.yml, octez.Dockerfile
  scripts/ bootstrap_ghostnet.sh, import_snapshot.sh, check_sync.sh, register_delegate.sh
  config/ ghostnet|mainnet node-config.json, baker.service, endorser.service
  monitoring/ grafana, prometheus, alertmanager
  runbooks/ start_stop, snapshot_restore, incidents
  security/ hardening_checklist.md, ufw_rules.md, remote_signer_ledger.md
  ci/ sanity_checks.yaml
```

## Key Commands (examples)
- Sync check: `tezos-client bootstrapped --block 2`
- Head lag: `scripts/check_sync.sh` (expect <2 for 60m)
- Compose: `docker compose -f docker/compose.ghostnet.yml up -d`
- Snapshot import: `scripts/import_snapshot.sh ghostnet`

## Milestones (DoD excerpts)
- M0 Bootstrap: structure + `.env.example`; CI sanity; `docker compose config` OK.
- M1 Node Up: image built/pulled; snapshot imported; lag <2 for 60m.
- M2 Delegate: faucet funds; registered; keys persisted/backed up.
- M3 Bake/Endorse: services healthy; at least one bake + one endorsement.
- M4 Monitoring: dashboards + alerts tested.
- M5 Resilience: network loss + restore drills documented.
- M6 Security: baseline hardening complete.
- M7–M8 Mainnet: signer tested; cutover and observe 48h.

## Environment (example keys)
```
TEZOS_NETWORK=ghostnet
OCTEZ_IMAGE=tezos/tezos:latest
DATA_DIR=/var/lib/tezos
P2P_PORT=9732
RPC_PORT=8732
GRAFANA_ADMIN=admin
GRAFANA_PASS=change_me
ALERT_EMAIL=you@example.com
```

See CONTRIBUTING, SECURITY, MONITORING, and runbooks in this folder.
