# Monitoring & Alerting

## Metrics to Watch
- Head lag (blocks behind), peers count, mempool size, and bootstrap status.
- Baking/endorsing rights: upcoming rights for the next 5 cycles and whether the signer is reachable.
- Missed rights: count of missed blocks/endorsements per cycle.
- CPU, RAM, disk %, IOPS, network errors; watchdog on disk fill rate.
- Service uptime for node, baker, endorser, remote signer, and exporters.

## Alerting (suggested)
- Head lag >5 blocks for 5m → WARN; >20 for 2m → CRIT.
- Peers <8 for 10m → WARN; <4 for 2m → CRIT.
- Missed rights ≥1 in a cycle → WARN; ≥3 or consecutive misses → CRIT.
- Signer RPC unreachable for 2m or signing latency >2s → CRIT.
- Disk >80% → WARN; >90% or fill rate >5%/hr → CRIT.
- CPU >85% for 10m or RAM >90% for 5m → WARN; sustained >95% → CRIT.
- Process down (baker/endorser/node/exporter) >1m → CRIT.
- No metrics ingestion >5m → CRIT.

## Stack
- Prometheus: scrape Octez metrics and node exporter; add blackbox exporter for RPC and signer endpoints.
- Grafana: import dashboards `monitoring/grafana_dashboards/*`; include panels for rights schedule and missed endorsements.
- Alertmanager: routes to Telegram/Email; annotate with runbook links and cycle/level context.

## Validation
- Fire synthetic alerts by pausing services, blocking signer RPC, and filling a small test disk.
- Confirm recovery clears alerts and dashboards reflect the state; capture screenshots for runbook evidence.
