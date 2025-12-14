# Runbook — Snapshot Restore

## Prepare
- Ensure disk space >= snapshot size ×1.5; stop baker/endorser.
- Backup keys: `scripts/backup_keys.sh` (verify artifact + decrypt test).

## Restore
1) Stop node: `docker compose ... stop octez-node`.
2) Import: `scripts/import_snapshot.sh ghostnet` (or mainnet on staging).
3) Start: `docker compose ... up -d octez-node`.
4) Verify: `tezos-client bootstrapped --block 2` then head lag <2 for 60m.

## Post-restore
- Re-enable baker/endorser; monitor first hour closely.
- Record RTO/RPO and anomalies in incidents log.
