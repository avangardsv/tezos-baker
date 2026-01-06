# Complete Guide: Remove Custom Monitoring & Migrate to Prometheus/Grafana

**Target Audience**: Less advanced AI assistants or developers
**Difficulty**: Easy
**Time Required**: 15-20 minutes
**Goal**: Reduce complexity from 7/10 to 3/10 by removing custom bash monitoring scripts

---

## Table of Contents

1. [Understanding the Current Problem](#understanding-the-current-problem)
2. [Understanding the Solution](#understanding-the-solution)
3. [Prerequisites](#prerequisites)
4. [Migration Steps](#migration-steps)
5. [Verification](#verification)
6. [Rollback Instructions](#rollback-instructions)
7. [Troubleshooting](#troubleshooting)

---

## Understanding the Current Problem

### What We Have Now (Custom Monitoring)

**Files that need to be removed**:
```
scripts/health-check.sh              170 lines - Bash script that checks node health
scripts/monitor-logs.sh              180 lines - Filters and monitors logs
scripts/monitor-watch.sh             120 lines - Watch mode for monitoring
.github/workflows/node-monitor.yml   200 lines - GitHub Actions workflow
```

**Total**: 670 lines of custom code that we maintain

**How it works now**:
1. `health-check.sh` runs and checks node status
2. Writes status to `logs/node-status.json` file
3. GitHub Actions reads the JSON file
4. Creates GitHub Issues if node is unhealthy
5. User gets notification via GitHub mobile app

**Problems**:
- ❌ We maintain 670 lines of bash code
- ❌ Bash scripts have bugs (JSON parsing, date formatting, etc.)
- ❌ No historical data (only current state)
- ❌ No graphs or visualizations
- ❌ GitHub Issues is a hacky notification method
- ❌ Hard to debug when things break

---

## Understanding the Solution

### What We're Migrating To (Prometheus + Grafana)

**What these tools do**:

**Prometheus**:
- Automatically collects metrics from Tezos node (port 9095)
- Stores metrics in time-series database
- Provides alerting capabilities
- Industry standard used by Google, AWS, etc.

**Grafana**:
- Creates beautiful dashboards from Prometheus data
- Shows graphs, charts, and status indicators
- Has official Tezos dashboards (Grafazos) ready to import
- Web UI accessible at http://localhost:3000

**Files we already have** (created in previous migration):
```
monitoring/docker-compose.yml    39 lines - Runs Prometheus + Grafana containers
monitoring/prometheus.yml        13 lines - Tells Prometheus to scrape port 9095
monitoring/README.md             52 lines - Documentation
```

**Total**: 104 lines of configuration (not code!)

**How it works**:
1. Tezos node already exposes metrics on port 9095 (built-in feature)
2. Prometheus automatically scrapes these metrics every 15 seconds
3. Grafana displays the metrics as graphs and dashboards
4. Alerts can be sent via email, Telegram, Slack, etc.

**Benefits**:
- ✅ Zero custom code to maintain (just config)
- ✅ Automatic metric collection
- ✅ Historical data (weeks of history)
- ✅ Beautiful graphs and dashboards
- ✅ Industry standard tools
- ✅ Official Tezos dashboards available

**Complexity Reduction**: 670 lines of code → 104 lines of config (-84%)

---

## Prerequisites

### Check What You Have

Run these commands to verify current state:

```bash
# 1. Check if monitoring config exists
ls -la monitoring/
# Expected output: docker-compose.yml, prometheus.yml, README.md

# 2. Check if custom scripts exist
ls -la scripts/health-check.sh
ls -la scripts/monitor-logs.sh
ls -la scripts/monitor-watch.sh
ls -la .github/workflows/node-monitor.yml
# Expected: All files should exist (we'll delete them)

# 3. Check if Tezos node is running
npm run ps
# Expected: tezos-node container should be running

# 4. Check if node exposes metrics
curl http://localhost:9095/metrics | head -5
# Expected: Should see metrics like "octez_node_..."
# If error "Connection refused": Node is not running, start it first
```

### What You Need

- Tezos node running and exposing port 9095
- Docker installed and running
- `monitoring/` directory with Prometheus/Grafana config (should already exist)
- Internet connection (to pull Prometheus/Grafana Docker images)

---

## Migration Steps

### STEP 1: Backup Current Setup

**Why**: Safety - we can rollback if needed

**Commands**:
```bash
# Create backup directory with timestamp
BACKUP_DIR="backups/monitoring-migration-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup custom monitoring scripts
cp scripts/health-check.sh "$BACKUP_DIR/" 2>/dev/null || echo "health-check.sh not found"
cp scripts/monitor-logs.sh "$BACKUP_DIR/" 2>/dev/null || echo "monitor-logs.sh not found"
cp scripts/monitor-watch.sh "$BACKUP_DIR/" 2>/dev/null || echo "monitor-watch.sh not found"
cp .github/workflows/node-monitor.yml "$BACKUP_DIR/" 2>/dev/null || echo "node-monitor.yml not found"

# Backup package.json
cp package.json "$BACKUP_DIR/package.json.backup"

# List what was backed up
echo "Backed up to: $BACKUP_DIR"
ls -lh "$BACKUP_DIR"
```

**Expected output**:
```
Backed up to: backups/monitoring-migration-20260103-120000
-rwxr-xr-x health-check.sh
-rwxr-xr-x monitor-logs.sh
-rwxr-xr-x monitor-watch.sh
-rw-r--r-- node-monitor.yml
-rw-r--r-- package.json.backup
```

**Verification**: Check backup exists
```bash
ls -lh "$BACKUP_DIR"
# Should show 5 files backed up
```

---

### STEP 2: Test Prometheus/Grafana Stack

**Why**: Verify new monitoring works BEFORE deleting old monitoring

**Commands**:
```bash
# Start Prometheus and Grafana
npm run monitoring:start

# Wait 10 seconds for containers to start
sleep 10

# Check containers are running
docker ps | grep -E "prometheus|grafana"
```

**Expected output**:
```
tezos-prometheus   prom/prometheus:latest      Up 10 seconds   0.0.0.0:9090->9090/tcp
tezos-grafana      grafana/grafana:latest      Up 10 seconds   0.0.0.0:3000->3000/tcp
```

**Verification Steps**:

1. **Check Prometheus is scraping metrics**:
   ```bash
   curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[0].health'
   # Expected output: "up"
   # If "down": Tezos node is not exposing metrics on port 9095
   ```

2. **Check metrics are being collected**:
   ```bash
   curl -s http://localhost:9095/metrics | grep "octez_node_block_level" | head -1
   # Expected output: octez_node_block_level{...} 17312258
   # This shows the current block height
   ```

3. **Access Grafana web interface**:
   ```bash
   echo "Open this URL in your browser: http://localhost:3000"
   echo "Username: admin"
   echo "Password: tezos_monitoring_2026"
   ```

4. **Manually test** (user must do this):
   - Open http://localhost:3000 in browser
   - Login with admin / tezos_monitoring_2026
   - You should see Grafana homepage
   - Click "Add your first data source"
   - Select "Prometheus"
   - URL: `http://prometheus:9090`
   - Click "Save & Test" - should show green "Data source is working"

**If any verification fails**: Stop here and debug the issue before proceeding

**If all verifications pass**: Prometheus/Grafana is working! Continue to next step.

---

### STEP 3: Delete Custom Monitoring Scripts

**Why**: Remove 670 lines of custom code we no longer need

**Commands**:
```bash
# Delete health check script
rm -f scripts/health-check.sh
echo "✓ Deleted scripts/health-check.sh"

# Delete monitor scripts
rm -f scripts/monitor-logs.sh
rm -f scripts/monitor-watch.sh
echo "✓ Deleted scripts/monitor-logs.sh and monitor-watch.sh"

# Delete GitHub Actions workflow
rm -f .github/workflows/node-monitor.yml
echo "✓ Deleted .github/workflows/node-monitor.yml"

# Check if .github/workflows directory is empty
if [ -z "$(ls -A .github/workflows 2>/dev/null)" ]; then
    rmdir .github/workflows
    echo "✓ Removed empty .github/workflows directory"
fi

# Check if .github directory is empty
if [ -z "$(ls -A .github 2>/dev/null)" ]; then
    rmdir .github
    echo "✓ Removed empty .github directory"
fi
```

**Expected output**:
```
✓ Deleted scripts/health-check.sh
✓ Deleted scripts/monitor-logs.sh and monitor-watch.sh
✓ Deleted .github/workflows/node-monitor.yml
✓ Removed empty .github/workflows directory
✓ Removed empty .github directory
```

**Verification**: Confirm files are deleted
```bash
# These should all return "No such file or directory"
ls scripts/health-check.sh 2>&1
ls scripts/monitor-logs.sh 2>&1
ls scripts/monitor-watch.sh 2>&1
ls .github/workflows/node-monitor.yml 2>&1

# Count how many files deleted
echo "Deleted custom monitoring scripts"
```

---

### STEP 4: Update package.json (Remove Custom Monitoring Scripts)

**Why**: Remove npm scripts that reference deleted files

**Files to edit**: `package.json`

**Scripts to DELETE** from package.json:
1. `"node:logs:filter": "./scripts/monitor-logs.sh"` - Script deleted
2. `"monitor:watch": "./scripts/monitor-watch.sh"` - Script deleted

**How to do it**:

**Option A - Automatic (using jq)**:
```bash
# Backup package.json (already done in STEP 1, but safe to do again)
cp package.json package.json.bak

# Remove the scripts using jq
jq 'del(.scripts."node:logs:filter") | del(.scripts."monitor:watch")' package.json > package.json.tmp
mv package.json.tmp package.json

echo "✓ Removed node:logs:filter and monitor:watch from package.json"
```

**Option B - Manual (if jq fails)**:
```bash
# Open package.json in editor
nano package.json

# Find and DELETE these two lines:
#   "node:logs:filter": "./scripts/monitor-logs.sh",
#   "monitor:watch": "./scripts/monitor-watch.sh",

# Save and exit (Ctrl+X, then Y, then Enter)
```

**Verification**: Check scripts are removed
```bash
# These should return "null" (meaning script doesn't exist)
cat package.json | jq '.scripts."node:logs:filter"'
cat package.json | jq '.scripts."monitor:watch"'

# Expected output for both: null

# Verify monitoring scripts are still there
cat package.json | jq '.scripts."monitoring:start"'
cat package.json | jq '.scripts."monitoring:stop"'
cat package.json | jq '.scripts."monitoring:logs"'

# Expected output: Should show the command strings (not null)
```

---

### STEP 5: Clean Up Status Files

**Why**: Remove JSON files created by old monitoring system

**Commands**:
```bash
# Remove node-status.json if it exists
rm -f logs/node-status.json
echo "✓ Removed logs/node-status.json"

# Check logs directory
ls -la logs/ 2>/dev/null || echo "logs/ directory doesn't exist (OK)"
```

**Expected output**:
```
✓ Removed logs/node-status.json
```

---

### STEP 6: Update Documentation

**Why**: README.md might reference old monitoring scripts

**Check if README mentions old monitoring**:
```bash
# Search for references to deleted scripts
grep -n "health-check\|monitor-logs\|monitor-watch\|node-monitor.yml" README.md

# If any matches found, you need to update README.md
```

**If matches found**:
```bash
# Open README.md and:
# 1. Remove references to health-check.sh, monitor-logs.sh, monitor-watch.sh
# 2. Add section about Prometheus/Grafana monitoring
# 3. Update monitoring instructions to use: npm run monitoring:start

nano README.md
```

**Add this section to README.md** (if not already present):
```markdown
## Monitoring

This project uses Prometheus and Grafana for monitoring.

### Start Monitoring
```bash
npm run monitoring:start
```

### Access Grafana Dashboard
- URL: http://localhost:3000
- Username: admin
- Password: tezos_monitoring_2026

### Add Prometheus Data Source
1. Click "Add data source"
2. Select "Prometheus"
3. URL: `http://prometheus:9090`
4. Click "Save & Test"

### Import Official Tezos Dashboard
- Official dashboards: https://gitlab.com/nomadic-labs/grafazos
- Download JSON dashboard and import into Grafana

### Stop Monitoring
```bash
npm run monitoring:stop
```
```

---

### STEP 7: Test Everything Works

**Why**: Verify the migration was successful

**Tests to run**:

**Test 1: Verify deleted files are gone**
```bash
# Should all fail (file not found)
test ! -f scripts/health-check.sh && echo "✓ health-check.sh deleted" || echo "✗ health-check.sh still exists"
test ! -f scripts/monitor-logs.sh && echo "✓ monitor-logs.sh deleted" || echo "✗ monitor-logs.sh still exists"
test ! -f scripts/monitor-watch.sh && echo "✓ monitor-watch.sh deleted" || echo "✗ monitor-watch.sh still exists"
test ! -f .github/workflows/node-monitor.yml && echo "✓ node-monitor.yml deleted" || echo "✗ node-monitor.yml still exists"
```

**Expected output**:
```
✓ health-check.sh deleted
✓ monitor-logs.sh deleted
✓ monitor-watch.sh deleted
✓ node-monitor.yml deleted
```

**Test 2: Verify monitoring stack is running**
```bash
# Check containers
docker ps | grep -E "prometheus|grafana"

# Expected: Two containers running
# tezos-prometheus   Up X minutes   0.0.0.0:9090->9090/tcp
# tezos-grafana      Up X minutes   0.0.0.0:3000->3000/tcp
```

**Test 3: Verify Prometheus is collecting metrics**
```bash
# Query Prometheus for current block height
curl -s 'http://localhost:9090/api/v1/query?query=octez_node_block_level' | jq '.data.result[0].value[1]'

# Expected output: "17312258" (or whatever current block height is)
# If empty result: Prometheus is not scraping metrics from node
```

**Test 4: Verify npm scripts work**
```bash
# Test monitoring scripts
npm run monitoring:logs 2>&1 | head -5

# Expected: Should show Prometheus and Grafana logs
```

**Test 5: Verify Grafana web UI works**
```bash
# Check Grafana is responding
curl -s http://localhost:3000/api/health | jq '.database'

# Expected output: "ok"
```

**Test 6: Count remaining scripts**
```bash
# Count shell scripts
ls -1 scripts/*.sh 2>/dev/null | wc -l

# Before migration: 13 scripts
# After migration: Should be 10 (3 monitoring scripts deleted)
```

**All tests passing?** ✅ Migration successful!

**Any test failing?** ❌ See Rollback Instructions or Troubleshooting section

---

### STEP 8: Commit Changes

**Why**: Save the migration in git history

**Commands**:
```bash
# Check what changed
git status

# Review changes
git diff package.json

# Stage all changes
git add -A

# Commit with descriptive message
git commit -m "Remove custom monitoring, migrate to Prometheus/Grafana

- Delete scripts/health-check.sh (170 lines)
- Delete scripts/monitor-logs.sh (180 lines)
- Delete scripts/monitor-watch.sh (120 lines)
- Delete .github/workflows/node-monitor.yml (200 lines)
- Remove node:logs:filter and monitor:watch from package.json
- Clean up logs/node-status.json
- Update documentation

Total reduction: 670 lines of custom code removed
Now using industry-standard Prometheus/Grafana (104 lines config)
Complexity reduced from 7/10 to 3/10

Migration verified:
- Prometheus collecting metrics ✓
- Grafana web UI accessible ✓
- Official Tezos dashboards available ✓"

# Push to remote (if applicable)
git push origin main
```

**Verification**: Check commit was created
```bash
git log -1 --oneline
# Should show your commit message
```

---

## Verification

### Complete Verification Checklist

Run this script to verify everything:

```bash
#!/bin/bash
echo "=== Monitoring Migration Verification ==="
echo ""

# Check custom scripts are deleted
echo "1. Checking custom scripts are deleted..."
ERRORS=0

if [ -f scripts/health-check.sh ]; then
    echo "   ✗ scripts/health-check.sh still exists"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✓ scripts/health-check.sh deleted"
fi

if [ -f scripts/monitor-logs.sh ]; then
    echo "   ✗ scripts/monitor-logs.sh still exists"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✓ scripts/monitor-logs.sh deleted"
fi

if [ -f scripts/monitor-watch.sh ]; then
    echo "   ✗ scripts/monitor-watch.sh still exists"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✓ scripts/monitor-watch.sh deleted"
fi

if [ -f .github/workflows/node-monitor.yml ]; then
    echo "   ✗ .github/workflows/node-monitor.yml still exists"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✓ .github/workflows/node-monitor.yml deleted"
fi

echo ""

# Check package.json updated
echo "2. Checking package.json updated..."
if grep -q "node:logs:filter" package.json; then
    echo "   ✗ node:logs:filter still in package.json"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✓ node:logs:filter removed from package.json"
fi

if grep -q "monitor:watch" package.json; then
    echo "   ✗ monitor:watch still in package.json"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✓ monitor:watch removed from package.json"
fi

echo ""

# Check Prometheus/Grafana running
echo "3. Checking Prometheus/Grafana running..."
if docker ps | grep -q tezos-prometheus; then
    echo "   ✓ Prometheus container running"
else
    echo "   ✗ Prometheus container not running"
    ERRORS=$((ERRORS + 1))
fi

if docker ps | grep -q tezos-grafana; then
    echo "   ✓ Grafana container running"
else
    echo "   ✗ Grafana container not running"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# Check Prometheus scraping metrics
echo "4. Checking Prometheus collecting metrics..."
METRICS=$(curl -s http://localhost:9095/metrics 2>/dev/null | grep -c "octez_node")
if [ "$METRICS" -gt 0 ]; then
    echo "   ✓ Node exposing $METRICS Tezos metrics"
else
    echo "   ✗ Node not exposing metrics on port 9095"
    ERRORS=$((ERRORS + 1))
fi

PROM_HEALTH=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null | jq -r '.data.activeTargets[0].health' 2>/dev/null)
if [ "$PROM_HEALTH" = "up" ]; then
    echo "   ✓ Prometheus scraping node metrics"
else
    echo "   ✗ Prometheus not scraping metrics (status: $PROM_HEALTH)"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# Check Grafana accessible
echo "5. Checking Grafana web UI..."
GRAFANA_HEALTH=$(curl -s http://localhost:3000/api/health 2>/dev/null | jq -r '.database' 2>/dev/null)
if [ "$GRAFANA_HEALTH" = "ok" ]; then
    echo "   ✓ Grafana web UI accessible at http://localhost:3000"
else
    echo "   ✗ Grafana not accessible"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# Final result
echo "=== Verification Result ==="
if [ $ERRORS -eq 0 ]; then
    echo "✅ All checks passed! Migration successful."
    echo ""
    echo "Next steps:"
    echo "1. Open http://localhost:3000 (admin / tezos_monitoring_2026)"
    echo "2. Add Prometheus data source (http://prometheus:9090)"
    echo "3. Import Grafazos dashboard from https://gitlab.com/nomadic-labs/grafazos"
    exit 0
else
    echo "❌ $ERRORS check(s) failed. See errors above."
    echo "Review the Troubleshooting section in the migration guide."
    exit 1
fi
```

**Save as**: `scripts/verify-monitoring-migration.sh`

**Run**:
```bash
chmod +x scripts/verify-monitoring-migration.sh
./scripts/verify-monitoring-migration.sh
```

---

## Rollback Instructions

### If Something Goes Wrong

**CRITICAL**: Only do this if migration failed and you need to restore old system

**Commands**:
```bash
# Find your backup directory
ls -lt backups/ | grep monitoring-migration | head -1

# Set backup directory (use actual path from above)
BACKUP_DIR="backups/monitoring-migration-YYYYMMDD-HHMMSS"  # Replace with actual

# Restore scripts
cp "$BACKUP_DIR/health-check.sh" scripts/ 2>/dev/null
cp "$BACKUP_DIR/monitor-logs.sh" scripts/ 2>/dev/null
cp "$BACKUP_DIR/monitor-watch.sh" scripts/ 2>/dev/null
chmod +x scripts/health-check.sh scripts/monitor-logs.sh scripts/monitor-watch.sh

# Restore GitHub Actions
mkdir -p .github/workflows
cp "$BACKUP_DIR/node-monitor.yml" .github/workflows/

# Restore package.json
cp "$BACKUP_DIR/package.json.backup" package.json

# Stop Prometheus/Grafana
npm run monitoring:stop

echo "✓ Rollback complete - old monitoring restored"
```

**Verification after rollback**:
```bash
ls -la scripts/health-check.sh scripts/monitor-logs.sh scripts/monitor-watch.sh
# All should exist

cat package.json | jq '.scripts."node:logs:filter"'
# Should show the script path (not null)
```

---

## Troubleshooting

### Problem 1: Prometheus shows target as "down"

**Symptoms**:
```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[0].health'
# Output: "down"
```

**Diagnosis**:
```bash
# Check if Tezos node is running
npm run ps | grep tezos-node

# Check if port 9095 is exposed
curl http://localhost:9095/metrics | head -5
```

**Solutions**:

If node not running:
```bash
npm run node:start
```

If port 9095 not accessible:
```bash
# Check node was started with metrics port
docker inspect tezos-node | jq '.[0].NetworkSettings.Ports'
# Should show "9095/tcp": [{"HostPort": "9095"}]
```

If port still not working:
```bash
# Restart node with metrics port
npm run node:stop
npm run node:start
```

---

### Problem 2: Grafana not accessible

**Symptoms**:
```bash
curl http://localhost:3000
# Connection refused
```

**Diagnosis**:
```bash
# Check if container is running
docker ps | grep grafana

# Check container logs
docker logs tezos-grafana | tail -20
```

**Solutions**:

If container not running:
```bash
# Restart monitoring stack
npm run monitoring:stop
npm run monitoring:start

# Wait 10 seconds
sleep 10

# Check again
docker ps | grep grafana
```

If port conflict (another service using 3000):
```bash
# Check what's using port 3000
lsof -i :3000

# Edit monitoring/docker-compose.yml
# Change "3000:3000" to "3001:3000" in grafana ports section
# Then restart: npm run monitoring:stop && npm run monitoring:start
# Access at http://localhost:3001 instead
```

---

### Problem 3: No metrics showing in Prometheus

**Symptoms**: Prometheus target is "up" but no metrics visible

**Diagnosis**:
```bash
# Check if node is exposing metrics
curl http://localhost:9095/metrics | grep "octez_node" | wc -l
# Should show >0 (number of metrics)
```

**Solutions**:

If 0 metrics:
```bash
# Node might not be fully started yet
# Wait 2 minutes and check again

# Check node logs for errors
npm run node:logs | tail -50
```

If still no metrics after 5 minutes:
```bash
# Restart node
npm run node:stop
npm run node:start
```

---

### Problem 4: jq command not found

**Symptoms**:
```bash
jq: command not found
```

**Solutions**:

Install jq:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Or skip automatic package.json edit and use manual method (Option B in STEP 4)
```

---

### Problem 5: Docker containers won't start

**Symptoms**:
```bash
npm run monitoring:start
# Error: Cannot start service prometheus: driver failed
```

**Diagnosis**:
```bash
# Check Docker is running
docker ps

# Check Docker disk space
docker system df
```

**Solutions**:

If Docker not running:
```bash
# Start Docker Desktop (macOS)
open -a Docker

# Or start Docker daemon (Linux)
sudo systemctl start docker
```

If disk space full:
```bash
# Clean up Docker
docker system prune -a --volumes

# Warning: This deletes unused containers, images, and volumes
# Tezos node container will NOT be deleted (it's running)
```

---

## Success Criteria

### Migration is successful when:

✅ All custom monitoring scripts deleted:
- `scripts/health-check.sh` - deleted
- `scripts/monitor-logs.sh` - deleted
- `scripts/monitor-watch.sh` - deleted
- `.github/workflows/node-monitor.yml` - deleted

✅ package.json updated:
- `node:logs:filter` script removed
- `monitor:watch` script removed
- `monitoring:start`, `monitoring:stop`, `monitoring:logs` scripts still present

✅ Prometheus/Grafana running:
- Prometheus accessible at http://localhost:9090
- Grafana accessible at http://localhost:3000
- Prometheus target status: "up"
- Metrics being collected

✅ Verification script passes:
```bash
./scripts/verify-monitoring-migration.sh
# Output: ✅ All checks passed! Migration successful.
```

✅ Commit created in git:
```bash
git log -1 --oneline | grep "monitoring"
```

---

## Next Steps After Migration

### 1. Set Up Grafana Dashboard

```bash
# 1. Open Grafana
open http://localhost:3000

# 2. Login
# Username: admin
# Password: tezos_monitoring_2026

# 3. Add Prometheus data source
# - Click "Add your first data source"
# - Select "Prometheus"
# - URL: http://prometheus:9090
# - Click "Save & Test"

# 4. Import Grafazos dashboard
# - Download from: https://gitlab.com/nomadic-labs/grafazos
# - Recommended: octez-compact.json (single page overview)
# - Click + (sidebar) → Import → Upload JSON file
```

### 2. Set Up Alerts (Optional)

Grafana can send alerts when:
- Node is stuck (no new blocks in X minutes)
- Peer count drops below threshold
- Sync lag exceeds threshold

**How to set up**:
1. In Grafana, go to Alerting → Alert rules
2. Create new alert rule
3. Example: "Block height hasn't increased in 10 minutes"
4. Add notification channel (email, Telegram, Slack)

### 3. Clean Up Old Backups (Optional)

After confirming migration works for a few days:
```bash
# List monitoring migration backups
ls -lh backups/monitoring-migration-*

# Delete old backups (keep git history as backup)
rm -rf backups/monitoring-migration-*
```

---

## Summary

### What We Removed
- 670 lines of custom bash code
- 1 GitHub Actions workflow
- 2 npm scripts
- JSON status files

### What We Kept
- 104 lines of Prometheus/Grafana config
- 3 npm scripts (monitoring:start, monitoring:stop, monitoring:logs)
- Industry-standard monitoring stack

### Complexity Reduction
- Before: 7/10 complexity
- After: 3/10 complexity
- **Improvement: 57% reduction**

### Time Saved
- No more debugging bash scripts
- No more maintaining custom monitoring code
- No more GitHub Actions errors
- Just use Grafana dashboard

---

## Reference Links

- **Official Tezos Monitoring Docs**: https://octez.tezos.com/user/node-monitoring.html
- **Grafazos (Official Dashboards)**: https://gitlab.com/nomadic-labs/grafazos
- **Prometheus Documentation**: https://prometheus.io/docs/
- **Grafana Documentation**: https://grafana.com/docs/

---

## Questions?

If this guide didn't work or you encountered issues:

1. Check the Troubleshooting section above
2. Run the verification script: `./scripts/verify-monitoring-migration.sh`
3. Check container logs: `npm run monitoring:logs`
4. Check Tezos node logs: `npm run node:logs`

**Remember**: You can always rollback using the backup created in STEP 1.
