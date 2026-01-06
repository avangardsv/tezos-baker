# Grafazos Setup Guide

## ✅ Status: NOT Legacy - Official & Active

Grafazos is the **official** Octez tool for Grafana dashboards.
- **Documentation**: https://octez.tezos.com/docs/grafazos-doc/
- **Status**: ✅ Active and maintained
- **Compatibility**: ✅ Works with Octez v23.1

## Quick Setup

### Prerequisites (Already Installed ✅)

- ✅ jsonnet v0.21.0
- ✅ jb (jsonnet-bundler) v0.6.0
- ✅ Prometheus running (port 9090)
- ✅ Grafana running (port 3000)

### Step 1: Clone Grafazos

**Option A: SSH (Recommended)**
```bash
cd data
git clone git@gitlab.com:tezos/grafazos.git
```

**Option B: HTTPS (Requires GitLab account)**
```bash
cd data
git clone https://gitlab.com/tezos/grafazos.git
```

**Option C: Download ZIP**
1. Visit: https://gitlab.com/tezos/grafazos
2. Download ZIP
3. Extract to `data/grafazos/`

### Step 2: Build Dashboards

```bash
cd data/grafazos
jb install          # Install grafonnet library
make compact       # Build compact dashboard (recommended)
# OR
make               # Build all dashboards
```

### Step 3: Import to Grafana

1. Access Grafana: http://localhost:3000
2. Login: `admin` / `tezos_monitoring_2026`
3. Go to: **Dashboards** → **Import**
4. Click **Upload JSON file**
5. Select: `data/grafazos/output/compact.json`
6. Click **Load**
7. Select Prometheus data source
8. Click **Import**

### Available Dashboards

- **compact**: Single-page overview (start here)
- **basic**: Detailed metrics
- **logs**: With logs (requires Loki)
- **full**: With hardware metrics (requires netdata)
- **dal-basic**: DAL node metrics

## Verification

### Check Metrics Available

```bash
curl http://localhost:9095/metrics | grep octez_validator_chain_head_level
```

### Check Prometheus Target

```bash
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[0].health'
# Should return: "up"
```

## Current Metrics

Your node is exposing these Grafazos-compatible metrics:
- `octez_validator_chain_head_level`
- `octez_validator_chain_is_bootstrapped`
- `octez_validator_chain_head_cycle`
- `octez_p2p_connections_active`
- And 50+ more metrics

## Troubleshooting

### Clone Fails

If GitLab clone fails:
1. Set up SSH key for GitLab
2. Or use HTTPS with GitLab credentials
3. Or download ZIP manually

### Dashboards Show No Data

1. Verify Prometheus data source URL: `http://prometheus:9090`
2. Check Prometheus is scraping: `curl http://localhost:9090/api/v1/targets`
3. Verify node metrics: `curl http://localhost:9095/metrics`

### Build Fails

```bash
# Reinstall dependencies
cd data/grafazos
rm -rf vendor
jb install
make clean
make compact
```

## Comparison: Grafazos vs Custom Dashboards

**Grafazos (Recommended)**:
- ✅ Pre-built, tested dashboards
- ✅ Official Octez tool
- ✅ Comprehensive metrics coverage
- ✅ Regular updates

**Custom Dashboards**:
- ✅ Full control
- ✅ Tailored to your needs
- ⚠️ More maintenance

**Recommendation**: Use Grafazos for standard monitoring, add custom panels for specific needs.
