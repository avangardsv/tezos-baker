# Complete Loki Setup Guide for Tezos Logs

## Overview

This guide will help you set up Loki to collect and display Tezos node logs in Grafana dashboards.

## Prerequisites

- ✅ Docker and Docker Compose installed
- ✅ Prometheus and Grafana already running
- ✅ Tezos node running in Docker

## Step-by-Step Setup

### Step 1: Configuration Files (Already Created ✅)

The following files have been created:
- `monitoring/promtail-config.yml` - Promtail configuration
- `monitoring/docker-compose.yml` - Updated with Loki services
- `scripts/setup-loki.sh` - Automated setup script
- `scripts/restore-grafazos-logs.sh` - Restore log panels

### Step 2: Start Loki and Promtail

```bash
cd monitoring
docker-compose up -d loki promtail
```

Verify they're running:
```bash
docker-compose ps loki promtail
```

You should see both containers as "Up".

### Step 3: Configure Loki Datasource in Grafana

1. **Access Grafana**: http://localhost:3000
2. **Login**: admin / tezos_monitoring_2026
3. **Go to**: Configuration → Data Sources → Add data source
4. **Select**: Loki
5. **Configure**:
   - **Name**: Loki
   - **URL**: `http://loki:3100`
   - **Access**: Server (default)
6. **Click**: Save & Test
7. **Note the UID**: After saving, note the datasource UID (shown in URL or datasource settings)

### Step 4: Update Grafazos Dashboards

After adding Loki datasource, update the dashboards:

```bash
# Restore log panels
./scripts/restore-grafazos-logs.sh

# Fix Loki datasource UID (replace <loki-uid> with actual UID)
./scripts/fix-loki-datasource.sh <loki-uid>
```

Or manually update in Grafana:
1. Import `octez-full.json` dashboard
2. Edit each log panel
3. Change datasource from "Loki" to your Loki datasource UID

### Step 5: Verify Logs are Being Collected

1. **In Grafana**: Go to **Explore**
2. **Select**: Loki datasource
3. **Query**: `{job="tezos-node"}`
4. **Click**: Run query

You should see log entries from your Tezos node.

## Quick Setup (Automated)

Run the automated setup script:

```bash
./scripts/setup-loki.sh
```

Then follow Step 3-5 above to configure Grafana.

## Troubleshooting

### No Logs Appearing

1. **Check Promtail is collecting**:
   ```bash
   docker logs tezos-promtail
   ```

2. **Check Loki is receiving**:
   ```bash
   docker logs tezos-loki
   ```

3. **Verify container names match**:
   ```bash
   docker ps --format "{{.Names}}" | grep tezos
   ```
   
   Promtail config looks for containers matching: `tezos-node`, `tezos-baker`, `tezos-*`

4. **Check Promtail config**:
   ```bash
   cat monitoring/promtail-config.yml
   ```

### Loki Datasource Not Found

- Ensure Loki is running: `docker ps | grep loki`
- Check URL in Grafana: Should be `http://loki:3100` (not `http://localhost:3100`)
- Verify network: Loki and Grafana must be on same Docker network

### Logs Not Showing in Dashboard

- Verify Loki datasource UID matches in dashboard
- Check log query syntax: `{job="tezos-node"}`
- Ensure Tezos node container name matches Promtail config

## Log Queries (LogQL)

Once Loki is set up, you can use LogQL queries:

**All Tezos node logs**:
```
{job="tezos-node"}
```

**Error logs only**:
```
{job="tezos-node"} |= "error"
```

**Logs from last hour**:
```
{job="tezos-node"} [1h]
```

**JSON parsing**:
```
{job="tezos-node"} | json | level="error"
```

## Architecture

```
┌──────────────┐     ┌──────────┐     ┌─────────┐     ┌──────────┐
│ Tezos Node   │────▶│ Promtail │────▶│  Loki   │────▶│  Grafana │
│ (Docker)     │     │(collector)│     │(storage)│     │(visualize)│
└──────────────┘     └──────────┘     └─────────┘     └──────────┘
```

- **Promtail**: Collects logs from Docker containers
- **Loki**: Stores and indexes logs
- **Grafana**: Queries and displays logs

## Verification Checklist

- [ ] Loki container running
- [ ] Promtail container running
- [ ] Loki datasource added in Grafana
- [ ] Logs visible in Grafana Explore
- [ ] Log panels working in Grafazos dashboards

## Next Steps

After setup:
1. Import updated `octez-full.json` dashboard
2. Log panels should now work
3. Explore logs in Grafana Explore
4. Set up log-based alerts if needed

## Resources

- Loki Docs: https://grafana.com/docs/loki/latest/
- LogQL: https://grafana.com/docs/loki/latest/logql/
- Promtail: https://grafana.com/docs/loki/latest/clients/promtail/
