# Grafana Dashboard Setup Guide

## Current Setup

- **Prometheus**: Running on port 9090
- **Grafana**: Running on port 3000 (admin/tezos_monitoring_2026)
- **Octez Node**: Exposing metrics on port 9095
- **Octez Version**: octez-v23.1

## Option 1: Use Grafazos (Official Pre-built Dashboards)

Grafazos is the **official** Octez tool for generating Grafana dashboards.
**Status**: ✅ Active and maintained (documented at https://octez.tezos.com/docs/grafazos-doc/)

### Setup Grafazos

1. **Clone Repository** (requires GitLab account):
   ```bash
   cd data
   git clone git@gitlab.com:tezos/grafazos.git
   # OR download ZIP from: https://gitlab.com/tezos/grafazos
   ```

2. **Install Dependencies**:
   ```bash
   # Install jsonnet (already installed ✅)
   brew install jsonnet
   
   # Install jsonnet-bundler (already installed ✅)
   go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
   ```

3. **Build Dashboards**:
   ```bash
   cd data/grafazos
   jb install  # Install grafonnet library
   make        # Build all dashboards
   # OR build specific dashboard:
   make compact  # Single-page overview
   make basic    # Detailed metrics
   make logs     # With logs (requires Loki)
   make full     # With hardware metrics (requires netdata)
   ```

4. **Import to Grafana**:
   - Access Grafana: http://localhost:3000
   - Login: admin / tezos_monitoring_2026
   - Go to: Dashboards → Import
   - Upload: `data/grafazos/output/compact.json`
   - Configure Prometheus data source if not already set

### Available Grafazos Dashboards

- **compact**: Single-page overview (recommended to start)
- **basic**: Detailed node metrics
- **logs**: Includes node logs (requires Loki/promtail)
- **full**: Includes hardware metrics (requires netdata)
- **dal-basic**: DAL node metrics

## Option 2: Create Custom Dashboards (Current Approach)

You can create dashboards directly in Grafana using the metrics exposed on port 9095.

### Key Metrics Available

- `octez_validator_chain_head_level` - Current block level
- `octez_validator_chain_is_bootstrapped` - Bootstrap status (1 = synced)
- `octez_validator_chain_head_cycle` - Current cycle
- `octez_validator_chain_head_round` - Current round
- `octez_p2p_connections_active` - Active peer connections
- `octez_store_last_merge_time` - Last store merge time

### Quick Dashboard Creation

1. In Grafana: **Dashboards** → **New Dashboard**
2. **Add Visualization** → **Prometheus**
3. Use metrics above to create panels
4. See `docs/GRAFANA_METRICS_GUIDE.md` (archived) for detailed examples

## Verification

### Check Metrics are Available

```bash
curl http://localhost:9095/metrics | grep octez | head -20
```

### Check Prometheus is Scraping

```bash
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[0].health'
# Should return: "up"
```

### Check Grafana Can Access Prometheus

1. Grafana → **Configuration** → **Data Sources**
2. Check Prometheus data source is configured
3. URL should be: `http://prometheus:9090` (from within Docker network)

## Compatibility

- **Grafazos**: ✅ Compatible with Octez v23.1
- **Metrics**: ✅ All standard Octez metrics available
- **Status**: ✅ Active and maintained (not legacy)

## Troubleshooting

### Grafazos Clone Fails

If GitLab clone fails:
1. Use SSH: `git clone git@gitlab.com:tezos/grafazos.git`
2. Or download ZIP from GitLab web interface
3. Or use custom dashboards (Option 2)

### Dashboards Don't Show Data

1. Verify Prometheus is scraping: `curl http://localhost:9090/api/v1/targets`
2. Check data source URL in Grafana (should be `http://prometheus:9090`)
3. Verify node is exposing metrics: `curl http://localhost:9095/metrics`

### Metrics Not Found

Ensure node is started with metrics flag:
```bash
npm run node:start
# Should include: --metrics-addr 0.0.0.0:9095
```

## References

- Grafazos Docs: https://octez.tezos.com/docs/grafazos-doc/
- Octez Metrics: https://octez.tezos.com/user/node-monitoring.html
- Grafazos Repository: https://gitlab.com/tezos/grafazos
