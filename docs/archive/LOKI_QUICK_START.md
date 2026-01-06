# Loki Quick Start Guide

## Complete Setup in 5 Steps

### Step 1: Start Loki & Promtail

```bash
cd monitoring
docker-compose up -d loki promtail
```

Verify they're running:
```bash
docker ps | grep -E "loki|promtail"
```

### Step 2: Add Loki Datasource in Grafana

1. **Open Grafana**: http://localhost:3000
2. **Login**: admin / tezos_monitoring_2026
3. **Go to**: Configuration (⚙️ gear icon) → Data Sources
4. **Click**: Add data source
5. **Select**: Loki
6. **Configure**:
   - **Name**: Loki (or leave default)
   - **URL**: `http://loki:3100` ⚠️ Important: Use `loki` not `localhost`
   - **Access**: Server (default)
7. **Click**: Save & Test
8. **Verify**: Should see "Data source connected and labels found"

### Step 3: Get Loki UID

**Option A: Use Helper Script (Easiest)**
```bash
./scripts/get-loki-uid.sh
```

**Option B: Manual Method**
1. After saving Loki datasource, look at the URL in your browser
2. Example URL: `http://localhost:3000/datasources/edit/abc123def456`
3. The UID is: `abc123def456` (the part after `/edit/`)

**Option C: API Method**
```bash
curl -u admin:tezos_monitoring_2026 http://localhost:3000/api/datasources | jq '.[] | select(.type=="loki") | .uid'
```

### Step 4: Restore Log Panels

```bash
./scripts/restore-grafazos-logs.sh
```

This restores the original `octez-full.json` with all log panels.

### Step 5: Fix Loki Datasource UID in Dashboards

```bash
# Replace <loki-uid> with the UID from Step 3
./scripts/fix-loki-datasource.sh <loki-uid>
```

**Example:**
```bash
./scripts/fix-loki-datasource.sh abc123def456
```

Or use the helper script:
```bash
./scripts/get-loki-uid.sh
# It will show you the exact command to run
```

### Step 6: Import Dashboard

1. **Go to**: Grafana → Dashboards → Import
2. **Upload**: `data/grafazos/output/octez-full.json`
3. **Select**: Prometheus datasource (for metrics)
4. **Select**: Loki datasource (for logs)
5. **Click**: Import

### Step 7: Verify Logs Work

1. **In Grafana**: Go to **Explore**
2. **Select**: Loki datasource
3. **Query**: `{job="tezos-node"}`
4. **Click**: Run query

You should see log entries from your Tezos node!

## Troubleshooting

### No Logs Appearing

**Check Promtail is collecting logs:**
```bash
docker logs tezos-promtail
```

**Check Loki is receiving logs:**
```bash
docker logs tezos-loki | tail -20
```

**Verify container names match:**
```bash
docker ps --format "{{.Names}}" | grep tezos
```

Promtail looks for containers matching: `tezos-node`, `tezos-baker`, `tezos-*`

**Check Promtail config:**
```bash
cat monitoring/promtail-config.yml
```

### Loki Datasource Not Found

- Ensure Loki is running: `docker ps | grep loki`
- Check URL in Grafana: Should be `http://loki:3100` (not `http://localhost:3100`)
- Verify network: All containers on same Docker network

### Can't Find Loki UID

Run the helper script:
```bash
./scripts/get-loki-uid.sh
```

Or check Grafana UI:
- Configuration → Data Sources → Click on Loki
- UID is in the browser URL

## Quick Reference

**Get Loki UID:**
```bash
./scripts/get-loki-uid.sh
```

**Restore log panels:**
```bash
./scripts/restore-grafazos-logs.sh
```

**Fix Loki UID:**
```bash
./scripts/fix-loki-datasource.sh <uid>
```

**Check logs:**
```bash
docker logs tezos-promtail
docker logs tezos-loki
```

## What Gets Restored

The `restore-grafazos-logs.sh` script:
- ✅ Restores `octez-full.json` from backup (with all log panels)
- ✅ Fixes Prometheus datasource UID
- ⚠️ Leaves Loki UID as "Loki" (needs manual fix in Step 5)

After Step 5, all log panels will work!
