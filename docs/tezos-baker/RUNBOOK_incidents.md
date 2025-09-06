# Runbook — Incidents

## Common Scenarios
- Head lag rising: check peers, disk IO, network, snapshot freshness.
- Baker not producing: verify rights, fees/limits, mempool settings, signer connectivity.
- RPC down: container health, host firewall, resource exhaustion.

## Triage Steps
1) Capture: timestamps, recent changes, affected services, metrics graphs.
2) Mitigate: scale resources, restart affected services, or fail over if configured.
3) Verify: head catches up; alerts clear; no data loss.
4) Document: root cause, actions, time to detect/resolve, follow-ups.

## Communication
- Page on CRIT alerts; post status in ops channel; update ticket/issue.
