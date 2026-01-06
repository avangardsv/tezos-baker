# What is Loki?

## Overview

**Loki** is a **log aggregation system** designed to work seamlessly with Grafana. It's part of the Grafana Labs ecosystem, similar to how Prometheus handles metrics.

## Simple Analogy

```
Prometheus = Metrics storage (numbers, counters, gauges)
Loki       = Logs storage (text messages, events)
```

## What Loki Does

1. **Collects Logs**: Gathers log files from your applications
2. **Stores Logs**: Efficiently stores log data (similar to Prometheus for metrics)
3. **Queries Logs**: Allows Grafana to query and visualize logs
4. **Integrates with Grafana**: Works seamlessly with Grafana dashboards

## Components

### Loki (Server)
- The main log storage system
- Receives logs from Promtail
- Provides query API for Grafana

### Promtail (Agent)
- Collects logs from files/system
- Sends logs to Loki
- Similar to Prometheus exporters

## Why Grafazos Needs Loki

The Grafazos dashboards have log panels that show:
- Node logs (Octez node output)
- Baker logs (baking operations)
- Accuser logs (accusation operations)
- System logs (OS/container logs)

These panels require Loki to:
1. Collect logs from Docker containers
2. Store them in Loki
3. Display them in Grafana dashboards

## Current Status

**Your Setup:**
- ✅ Prometheus (metrics) - Running
- ✅ Grafana (visualization) - Running
- ❌ Loki (logs) - Not installed
- ❌ Promtail (log collector) - Not installed

**Result:** Log panels in Grafazos dashboards show errors because Loki isn't available.

## Do You Need Loki?

### You DON'T need Loki if:
- ✅ You only want metrics (block level, connections, etc.)
- ✅ You can check logs manually: `docker logs tezos-node`
- ✅ You're happy with basic monitoring

### You DO need Loki if:
- 📊 You want log visualization in Grafana
- 📊 You want to search logs through Grafana UI
- 📊 You want log-based alerts
- 📊 You want to correlate logs with metrics

## Quick Setup (Optional)

If you want to add Loki for log panels:

### 1. Add to monitoring/docker-compose.yml:

```yaml
services:
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - ./monitoring/loki-config.yml:/etc/loki/local-config.yaml
    command: -config.file=/etc/loki/local-config.yaml

  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock
      - ./monitoring/promtail-config.yml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml
```

### 2. Configure Promtail to collect Docker logs

### 3. Add Loki datasource in Grafana

### 4. Re-import Grafazos dashboards (they'll now show logs)

## Alternative: View Logs Without Loki

You can always view logs directly:

```bash
# Node logs
docker logs tezos-node

# Baker logs  
docker logs tezos-baker

# Follow logs
docker logs -f tezos-node
```

## Summary

- **Loki** = Log storage system (like Prometheus for metrics)
- **Promtail** = Log collector (like exporters for Prometheus)
- **Not required** for basic monitoring (metrics work fine without it)
- **Useful** if you want log visualization in Grafana
- **Your current setup** works perfectly for metrics monitoring

**Recommendation:** You don't need Loki unless you specifically want log visualization in Grafana. Your current Prometheus + Grafana setup is perfect for monitoring Octez metrics!
