# Monitoring & Alerting

## Metrics to Watch
- Head lag (blocks behind), peers count, mempool size.
- CPU, RAM, disk %, IOPS, network errors.
- Missed endorsements/blocks; upcoming rights schedule.

## Alerting (suggested)
- Head lag >5 blocks for 5m → WARN; >20 for 2m → CRIT.
- Disk >80% → WARN; >90% → CRIT.
- Process down (baker/endorser/node) >1m → CRIT.
- No metrics ingestion >5m → CRIT.

## Stack
- Prometheus: scrape Octez metrics and node exporter.
- Grafana: import dashboards `monitoring/grafana_dashboards/*`.
- Alertmanager: routes to Telegram/Email; annotate with runbook links.

## Validation
- Fire synthetic alerts by pausing services and filling a small test disk.
- Confirm recovery clears alerts and dashboards reflect the state.
