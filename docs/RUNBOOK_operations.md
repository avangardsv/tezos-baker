# Runbook — Operations, Backups, and Recovery

## Incident Response
1. **Detect & capture:** Confirm alert (head lag, missed rights, signer errors). Capture timestamps, Grafana panels, recent deploys.
2. **Stabilize:**
   - If head lag >20 blocks: check peers and disk; restart node only after snapshot freshness confirmed.
   - If missed rights/signer errors: verify signer RPC (6732), Ledger unlocked, and authorization list; fail over to backup signer if outage >5m.
3. **Communicate:** Page on CRIT alerts. Post status in ops channel with ETA and owner. Open ticket and link dashboards.
4. **Validate:** Ensure node bootstrapped, peers >=10, signer latency <2s, alerts cleared. Confirm next scheduled right executes.
5. **Document:** Root cause, timeline, actions, follow-ups; add to change log.

## Log Retention & Audit
- Octez logs rotated daily with 7-day hot retention; archive weekly to S3/object storage with 90-day retention.
- Signer audit logs retained 180 days; restrict access to auditors and ops leads.
- Export Alertmanager notifications to ticketing system for traceability.

## Snapshot & Backup Cadence
- **Node snapshots:** Create daily snapshots after cycle completion; keep last 7 daily + 4 weekly. Verify import monthly on staging node.
- **Signer configs/ACLs:** Weekly encrypted backup with integrity check (sha256 + signature).
- **Critical scripts/config:** Version-controlled; nightly git mirror to secondary repo or artifact store.

## Restore Procedures
- **Node:**
  1. Stop services; clear data dir except identity keys.
  2. Import latest snapshot with `./scripts/import_snapshot.sh <network>`.
  3. Restart node; verify bootstrap and peers.
- **Signer:**
  1. Provision spare signer host; apply hardened baseline.
  2. Restore encrypted config/ACL backup; pair hardware wallet; validate with Ghostnet dry-run signing.
  3. Update node to point at new signer; revoke old signer authorization.

## Disaster Recovery Drill
- Quarterly: rebuild full stack on Ghostnet using last weekly backups (snapshot + signer config).
- Success criteria: node bootstraps <30m, signer reachable, bake/endorse one right, alerts green.
- Record drill report (time to recover, gaps, owners) and track remediation in backlog.
