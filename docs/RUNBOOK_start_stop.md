# Runbook — Start/Stop & Health

## Start (Ghostnet)
1) Export env: `set -a && source .env && set +a`.
2) Launch: `docker compose -f docker/compose.ghostnet.yml up -d`.
3) Verify node: `tezos-client bootstrapped --block 2` (repeat until OK).
4) Check lag: `scripts/check_sync.sh` (<2 for 60m).
5) Start baker/endorser services; confirm healthchecks pass.

## Stop
1) Drain: wait for non-critical window (no immediate rights).
2) Stop services: `docker compose ... stop octez-baker octez-endorser`.
3) Stop node if needed: `docker compose ... stop octez-node`.
4) Confirm clean shutdown in logs.

## Health Checks
- RPC: `curl -sf http://localhost:${RPC_PORT}/chains/main/blocks/head`.
- Progress: block level increases over time; peers >8.
- Services: `docker compose ps` shows `healthy`.
