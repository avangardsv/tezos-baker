# Grafazos Dashboard Import Guide

## ✅ Dashboards Fixed

All Grafazos dashboards have been fixed to use your Prometheus datasource UID: `af91eh6msq874c`

## Issue Found & Fixed

**Problem:**
- Grafazos dashboards used datasource UID `"Prometheus"` (name) instead of your actual UID
- Panel datasources used `"-- Mixed --"` instead of Prometheus

**Fix Applied:**
- ✅ All datasource references updated to: `{"type": "prometheus", "uid": "af91eh6msq874c"}`
- ✅ Both panel-level and target-level datasources fixed

## Import Steps

1. **Access Grafana**: http://localhost:3000
2. **Login**: `admin` / `tezos_monitoring_2026`
3. **Go to**: Dashboards → Import
4. **Upload**: `data/grafazos/output/octez-compact.json`
5. **Select**: Prometheus datasource (should auto-select)
6. **Click**: Import

## Available Dashboards

- **octez-compact.json** - Single-page overview (recommended to start)
- **octez-basic.json** - Detailed metrics
- **octez-with-logs.json** - With logs (requires Loki)
- **octez-full.json** - With hardware metrics (requires netdata)

## Template Variables

Grafazos dashboards may use template variables like `$node_instance`. 

**If dashboards show no data:**
1. Check if `$node_instance` variable is set
2. In Grafana: Dashboard Settings → Variables
3. Set `node_instance` to your instance label (or remove from queries)

**Quick Fix**: Remove instance filtering from queries if not needed:
- Change: `octez_metric{instance="$node_instance"}`
- To: `octez_metric`

## Verification

After import, verify:
1. ✅ Dashboard loads without errors
2. ✅ Panels show data (not "No data")
3. ✅ Metrics match your node (check current block level)

## Troubleshooting

### No Data Showing

1. **Check Prometheus is scraping**:
   ```bash
   curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[0].health'
   # Should return: "up"
   ```

2. **Check metrics are available**:
   ```bash
   curl http://localhost:9095/metrics | grep octez_validator_chain_head_level
   ```

3. **Check template variables**:
   - Dashboard Settings → Variables
   - Ensure `node_instance` matches your instance label
   - Or remove instance filtering from queries

### Datasource Errors

If you see "Datasource not found":
1. Verify Prometheus datasource exists: Configuration → Data Sources
2. Check datasource UID matches: `af91eh6msq874c`
3. Re-run fix script: `./scripts/fix-grafazos-dashboards.sh`

## Comparison: Grafazos vs Your POC

**Your POC** (working):
- Simple queries: `octez_p2p_connections_active`
- No instance filtering
- Direct metric access

**Grafazos** (fixed):
- Uses instance filtering: `octez_metric{instance="$node_instance"}`
- More comprehensive (50+ metrics)
- Pre-built panels and layouts

**Recommendation**: Use Grafazos for comprehensive monitoring, keep your POC for quick checks.
