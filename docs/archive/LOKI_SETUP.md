# Loki Setup Instructions

## Step 1: Start Loki & Promtail

```bash
cd monitoring
docker-compose up -d loki promtail
```

Verify they're running:
```bash
docker ps | grep -E "loki|promtail"
```

## Step 2: Add Loki Datasource in Grafana

1. **Open Grafana**: http://localhost:3000
2. **Login**: admin / tezos_monitoring_2026
3. **Go to**: Configuration (⚙️) → Data Sources
4. **Click**: Add data source
5. **Select**: Loki
6. **Configure**:
   - **URL**: `http://loki:3100` (use `loki` not `localhost`)
   - **Access**: Server (default)
7. **Click**: Save & Test
8. **Verify**: Should see "Data source connected and labels found"

## Step 3: Find Loki UID

After saving Loki datasource, find the UID:

**Method 1: From Browser URL**
- Look at the URL in your browser
- Example: `http://localhost:3000/datasources/edit/abc123def456`
- The UID is: `abc123def456` (part after `/edit/`)

**Method 2: From API**
```bash
curl -u admin:tezos_monitoring_2026 http://localhost:3000/api/datasources | jq '.[] | select(.type=="loki") | .uid'
```

## Step 4: Restore Log Panels

Restore the original dashboard with log panels:

```bash
# Restore from backup
cp data/grafazos/output/octez-full.json.backup data/grafazos/output/octez-full.json
```

## Step 5: Fix Datasource UIDs

Update the dashboard to use your Prometheus and Loki UIDs:

**Your Prometheus UID**: `af91eh6msq874c` (already configured)

**Your Loki UID**: Use the UID from Step 3

**Fix using jq**:
```bash
# Replace <loki-uid> with your actual Loki UID from Step 3
LOKI_UID="<loki-uid>"  # Replace this!
PROMETHEUS_UID="af91eh6msq874c"

jq --arg prom_uid "$PROMETHEUS_UID" --arg loki_uid "$LOKI_UID" '
  # Fix Prometheus datasources
  (.. | objects | select(has("datasource") and (.datasource.type == "prometheus"))) |=
    .datasource = {"type": "prometheus", "uid": $prom_uid} |
  
  # Fix Loki datasources
  (.. | objects | select(has("datasource") and (.datasource.type == "loki"))) |=
    .datasource = {"type": "loki", "uid": $loki_uid} |
  
  # Fix panel datasources (-- Mixed --)
  (.. | objects | select(has("datasource") and (.datasource.uid == "-- Mixed --"))) |=
    .datasource = {"type": "prometheus", "uid": $prom_uid}
' data/grafazos/output/octez-full.json > data/grafazos/output/octez-full.json.tmp && \
mv data/grafazos/output/octez-full.json.tmp data/grafazos/output/octez-full.json
```

**Or manually edit in Grafana**:
1. Import dashboard: `data/grafazos/output/octez-full.json`
2. Edit each panel that shows errors
3. Change datasource to your Prometheus/Loki datasource

## Step 6: Import Dashboard

1. **In Grafana**: Dashboards → Import
2. **Upload**: `data/grafazos/output/octez-full.json`
3. **Select datasources**: Prometheus and Loki
4. **Click**: Import

## Step 7: Verify Logs Work

1. **In Grafana**: Go to **Explore**
2. **Select**: Loki datasource
3. **Query**: `{job="tezos-node"}`
4. **Click**: Run query

You should see log entries from your Tezos node!

## Troubleshooting

### No Logs Appearing

**Check Promtail**:
```bash
docker logs tezos-promtail
```

**Check Loki**:
```bash
docker logs tezos-loki | tail -20
```

**Verify container names**:
```bash
docker ps --format "{{.Names}}" | grep tezos
```

Promtail looks for containers matching: `tezos-node`, `tezos-baker`, `tezos-*`

### Can't Find Loki UID

**From Grafana UI**:
- Configuration → Data Sources → Click on Loki
- UID is in the browser URL: `/datasources/edit/<UID>`

**From API**:
```bash
curl -u admin:tezos_monitoring_2026 http://localhost:3000/api/datasources | jq '.[] | select(.type=="loki") | .uid'
```

## Quick Reference

**Prometheus UID**: `af91eh6msq874c` (already configured)

**Loki UID**: Find it in Step 3 above

**Restore dashboard**:
```bash
cp data/grafazos/output/octez-full.json.backup data/grafazos/output/octez-full.json
```

**Check logs**:
```bash
docker logs tezos-promtail
docker logs tezos-loki
```
