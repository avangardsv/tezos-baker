# What is Loki?

## Overview

**Loki** is a **log aggregation system** designed to work seamlessly with Grafana. It's part of the Grafana Labs ecosystem (like Prometheus and Grafana).

## What It Does

Loki collects, stores, and queries logs from your applications and services. Think of it as:
- **Prometheus** = metrics (numbers, counters, gauges)
- **Loki** = logs (text messages, error logs, application logs)

## Architecture

```
┌─────────────┐     ┌──────────┐     ┌─────────┐     ┌──────────┐
│  Tezos Node │────▶│ Promtail │────▶│  Loki   │────▶│  Grafana │
│   (logs)    │     │(collector)│     │(storage)│     │(visualize)│
└─────────────┘     └──────────┘     └─────────┘     └──────────┘
```

1. **Promtail** - Collects logs from files/containers
2. **Loki** - Stores and indexes logs
3. **Grafana** - Queries and visualizes logs

## Why Grafazos Needs It

The Grafazos `full` and `with-logs` dashboards include panels like:
- "Node logs" - Shows Tezos node log messages
- "Baker logs" - Shows baker process logs
- "System logs" - Shows system-level logs

These panels query Loki to display log entries in Grafana.

## Current Setup

**You DON'T have Loki installed:**
- ✅ Prometheus (metrics) - Running
- ✅ Grafana (visualization) - Running
- ❌ Loki (logs) - Not installed
- ❌ Promtail (log collector) - Not installed

That's why those log panels showed errors!

## Do You Need Loki?

**For most monitoring: NO**
- Prometheus metrics (what you have) cover 95% of monitoring needs
- Metrics show: block level, connections, sync status, etc.
- Logs are mainly for debugging specific issues

**You might want Loki if:**
- You need to search through node logs
- You want to correlate errors with metrics
- You're debugging specific issues
- You want full observability (metrics + logs)

## Comparison

| Feature | Prometheus (Metrics) | Loki (Logs) |
|---------|---------------------|-------------|
| **Data Type** | Numbers, counters | Text messages |
| **Example** | `octez_p2p_connections_active = 42` | `"2026-01-04 INFO: New peer connected"` |
| **Use Case** | Monitoring, alerts | Debugging, investigation |
| **Storage** | Time-series DB | Log storage |
| **Query** | PromQL | LogQL |

## Example Log Query (LogQL)

```logql
{job="tezos-node"} |= "error" | json | level="error"
```

This finds all error-level logs from the Tezos node.

## Setup (If You Want It)

If you want to add Loki for log monitoring:

```yaml
# Add to monitoring/docker-compose.yml
services:
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
  
  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./promtail-config.yml:/etc/promtail/config.yml
```

Then configure Promtail to collect Docker container logs.

## Recommendation

**For your Tezos baker setup:**
- ✅ **Current setup is perfect** - Prometheus + Grafana covers all monitoring needs
- ✅ **Metrics are more important** - Block level, sync status, connections
- ⚠️ **Logs are optional** - Only needed for deep debugging

**Stick with what you have** unless you specifically need to search through logs!

## Resources

- Loki Docs: https://grafana.com/docs/loki/latest/
- LogQL: https://grafana.com/docs/loki/latest/logql/
- Promtail: https://grafana.com/docs/loki/latest/clients/promtail/
