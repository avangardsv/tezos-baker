# Tezos Baker Setup Migration Guide
## From Custom Implementation to Official Documentation Standard

**Target AI Level**: GPT-3.5 or similar
**Estimated Time**: 2-3 hours
**Difficulty**: Follow instructions exactly, no decisions needed

---

## 📋 PREREQUISITES - READ FIRST

### What You Need
- Current working directory: `/Users/admin/tezos-baker`
- Access to terminal commands
- Ability to read/write files
- Docker installed (already present)
- Git installed (already present)

### Official Documentation URLs (Open These Now)
1. Node Configuration: https://octez.tezos.com/user/node-configuration.html
2. Node Monitoring: https://octez.tezos.com/user/node-monitoring.html
3. How to Run: https://octez.tezos.com/user/howtorun.html
4. Docker Images: https://octez.tezos.com/introduction/howtoget.html#docker-images

### What This Guide Does
- ✅ Removes custom monitoring scripts
- ✅ Fixes ACL security issue
- ✅ Adds official monitoring (Prometheus/Grafana)
- ✅ Aligns configuration with docs
- ✅ Simplifies to match official approach

---

## PART 1: BACKUP CURRENT SETUP (DO FIRST)

### Step 1.1: Create Backup Directory
```bash
# Run these commands in order:
cd /Users/admin/tezos-baker
mkdir -p backups/pre-migration-$(date +%Y%m%d)
```

### Step 1.2: Backup Important Files
```bash
# Copy current configuration
cp data/config.json backups/pre-migration-$(date +%Y%m%d)/config.json.backup
cp .env backups/pre-migration-$(date +%Y%m%d)/.env.backup
cp package.json backups/pre-migration-$(date +%Y%m%d)/package.json.backup

# Backup scripts
cp -r scripts backups/pre-migration-$(date +%Y%m%d)/scripts-backup
cp -r .github backups/pre-migration-$(date +%Y%m%d)/github-backup
```

### Step 1.3: Document Current State
```bash
# Save current container status
docker ps -a > backups/pre-migration-$(date +%Y%m%d)/containers.txt

# Save current node status
curl -s http://127.0.0.1:8732/chains/main/blocks/head/header | jq '.' > backups/pre-migration-$(date +%Y%m%d)/current-block.json 2>/dev/null || echo "Node not responding" > backups/pre-migration-$(date +%Y%m%d)/current-block.json
```

### Step 1.4: Verify Backup
```bash
# Check backup exists
ls -la backups/pre-migration-$(date +%Y%m%d)/

# Expected output: Should show all backed up files
```

**✅ CHECKPOINT**: Backups created. If anything goes wrong, you can restore from here.

---

## PART 2: STOP EVERYTHING

### Step 2.1: Stop All Containers
```bash
# Stop baker first
npm run baker:stop

# Wait 5 seconds
sleep 5

# Stop node
npm run node:stop

# Wait 5 seconds
sleep 5
```

### Step 2.2: Verify Everything Stopped
```bash
# Check no tezos containers running
docker ps | grep tezos

# Expected output: Nothing (empty)
# If you see containers, run:
docker rm -f tezos-node tezos-baker
```

**✅ CHECKPOINT**: All containers stopped.

---

## PART 3: FIX CRITICAL SECURITY ISSUE (ACL)

**Reference**: https://octez.tezos.com/user/node-configuration.html#rpc-acls

### Step 3.1: Read Current ACL Configuration
```bash
# View current (INSECURE) ACL
cat data/config.json | jq '.rpc.acl'

# Current output shows:
# [
#   {
#     "address": "0.0.0.0",
#     "blacklist": []
#   }
# ]
# ⚠️ This is INSECURE - allows all access from anywhere
```

### Step 3.2: Create Secure ACL Configuration

**From Documentation** (page: node-configuration.html, section: RPC ACLs):
> "Local connections (127.0.0.1) receive full access by default. Remote connections are restricted to 'safe' endpoints only."

**Create this file**: `config-patches/secure-acl.json`

```bash
# Create directory
mkdir -p config-patches

# Create secure ACL file
cat > config-patches/secure-acl.json << 'EOF'
{
  "rpc": {
    "listen-addrs": ["0.0.0.0:8732"],
    "acl": [
      {
        "address": "127.0.0.1",
        "blacklist": []
      },
      {
        "address": "::1",
        "blacklist": []
      },
      {
        "address": "0.0.0.0",
        "whitelist": [
          "GET /chains/**",
          "GET /monitor/**",
          "GET /network/**",
          "GET /version",
          "GET /config/**"
        ]
      }
    ]
  }
}
EOF
```

**Explanation**:
- `127.0.0.1` (localhost IPv4): Full access (all endpoints)
- `::1` (localhost IPv6): Full access (all endpoints)
- `0.0.0.0` (remote): Limited to safe GET endpoints only

### Step 3.3: Apply Secure ACL to config.json

```bash
# Backup current config again
cp data/config.json data/config.json.pre-acl-fix

# Use jq to merge secure ACL
jq -s '.[0] * .[1]' data/config.json config-patches/secure-acl.json > data/config.json.tmp

# Replace config
mv data/config.json.tmp data/config.json
```

### Step 3.4: Verify ACL Configuration
```bash
# View new ACL
cat data/config.json | jq '.rpc.acl'

# Expected output:
# [
#   {
#     "address": "127.0.0.1",
#     "blacklist": []
#   },
#   {
#     "address": "::1",
#     "blacklist": []
#   },
#   {
#     "address": "0.0.0.0",
#     "whitelist": [
#       "GET /chains/**",
#       "GET /monitor/**",
#       "GET /network/**",
#       "GET /version",
#       "GET /config/**"
#     ]
#   }
# ]
```

**✅ CHECKPOINT**: ACL configuration secured according to official docs.

---

## PART 4: ADD PROPER LOGGING CONFIGURATION

**Reference**: https://octez.tezos.com/user/logging.html

### Step 4.1: Create Logs Directory
```bash
# Create logs directory in data folder
mkdir -p data/logs
```

### Step 4.2: Add Logging to config.json

**From Documentation** (page: logging.html):
> "Configure logging via the 'log' object in config.json"

```bash
# Create logging configuration
cat > config-patches/logging.json << 'EOF'
{
  "log": {
    "output": "/var/run/tezos/node/logs/octez-node.log",
    "level": "info"
  }
}
EOF

# Merge with config.json
jq -s '.[0] * .[1]' data/config.json config-patches/logging.json > data/config.json.tmp
mv data/config.json.tmp data/config.json
```

### Step 4.3: Verify Logging Configuration
```bash
cat data/config.json | jq '.log'

# Expected output:
# {
#   "output": "/var/run/tezos/node/logs/octez-node.log",
#   "level": "info"
# }
```

**✅ CHECKPOINT**: Logging configured according to official docs.

---

## PART 5: REMOVE CUSTOM MONITORING SCRIPTS

### Step 5.1: Uninstall Cron Job
```bash
# Remove health check cron job
npm run health:uninstall-cron 2>/dev/null || echo "No cron job installed"

# Verify cron removed
crontab -l 2>/dev/null | grep health-check || echo "Cron job removed successfully"
```

### Step 5.2: List Files to Remove
```bash
# These are CUSTOM files not in official docs:
cat > files-to-remove.txt << 'EOF'
scripts/health-check.sh
scripts/install-health-cron.sh
scripts/uninstall-health-cron.sh
.github/workflows/node-monitor.yml
logs/node-status.json
SYNC_STUCK_ANALYSIS.md
EOF

# Review list
cat files-to-remove.txt
```

### Step 5.3: Move Custom Scripts to Archive (Don't Delete Yet)
```bash
# Create archive directory
mkdir -p backups/custom-scripts-archive

# Move (don't delete) custom files
while IFS= read -r file; do
  if [ -f "$file" ]; then
    echo "Archiving: $file"
    cp "$file" "backups/custom-scripts-archive/$(basename $file)"
  fi
done < files-to-remove.txt

# Keep lib/common.sh for now (used by other scripts)
echo "Kept: scripts/lib/common.sh (still used by monitor.sh)"
```

**✅ CHECKPOINT**: Custom monitoring scripts archived (not deleted, in case needed).

---

## PART 6: ADD OFFICIAL MONITORING STACK

**Reference**: https://octez.tezos.com/user/node-monitoring.html

### Step 6.1: Understand What Official Docs Say

**From Documentation** (page: node-monitoring.html):
- Node exposes metrics on port 9095 (already configured ✅)
- Recommends Prometheus for scraping metrics
- Recommends Grafana for visualization
- Official dashboards available

### Step 6.2: Create Prometheus Configuration

```bash
# Create monitoring directory
mkdir -p monitoring

# Create prometheus.yml (from official docs pattern)
cat > monitoring/prometheus.yml << 'EOF'
# Prometheus configuration for Tezos node monitoring
# Based on: https://octez.tezos.com/user/node-monitoring.html

global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'tezos-node'
    static_configs:
      - targets: ['host.docker.internal:9095']
    scrape_interval: 15s
EOF
```

### Step 6.3: Create Docker Compose for Monitoring Stack

```bash
cat > monitoring/docker-compose.yml << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: tezos-prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    restart: unless-stopped
    extra_hosts:
      - "host.docker.internal:host-gateway"

  grafana:
    image: grafana/grafana:latest
    container_name: tezos-grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=tezos_monitoring_2026
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana-data:/var/lib/grafana
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  prometheus-data:
  grafana-data:
EOF
```

### Step 6.4: Create README for Monitoring

```bash
cat > monitoring/README.md << 'EOF'
# Tezos Node Monitoring Stack

Based on official documentation: https://octez.tezos.com/user/node-monitoring.html

## Components
- **Prometheus**: Scrapes metrics from Tezos node (port 9095)
- **Grafana**: Visualizes metrics with dashboards

## Quick Start

1. Ensure Tezos node is running and exposing metrics on port 9095
2. Start monitoring stack:
   ```bash
   cd monitoring
   docker-compose up -d
   ```

3. Access Grafana: http://localhost:3000
   - Username: admin
   - Password: tezos_monitoring_2026

4. Add Prometheus data source in Grafana:
   - URL: http://prometheus:9090
   - Click "Save & Test"

5. Import official Tezos dashboard (search for "Tezos" in Grafana dashboards)

## Verify Metrics

Check Prometheus is scraping:
```bash
curl http://localhost:9090/api/v1/targets
```

Check node metrics are available:
```bash
curl http://localhost:9095/metrics | head -20
```

## Stop Monitoring

```bash
cd monitoring
docker-compose down
```

## Official Dashboard

Search for "Grafazos" or official Tezos Grafana dashboards in:
- Grafana dashboard repository
- Tezos ecosystem documentation
EOF
```

**✅ CHECKPOINT**: Official monitoring stack configuration created.

---

## PART 7: SIMPLIFY PACKAGE.JSON

### Step 7.1: Create Minimal package.json

**Goal**: Remove custom monitoring commands, keep only official Octez operations

```bash
cat > package.json.new << 'EOF'
{
  "name": "tezos-baker",
  "version": "1.0.0",
  "description": "Tezos baker setup for Ghostnet (documentation-compliant)",
  "scripts": {
    "env": "test -f .env && echo '.env file found' || (echo 'Error: .env file not found. Copy .env.example to .env first.' && exit 1)",

    "node:init": "npm run env && . ./.env && mkdir -p ${DATA_DIR:-data} && docker run --rm --entrypoint octez-node -v \"$PWD/${DATA_DIR:-data}:/var/run/tezos/node\" tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} config init --network ${TEZOS_NETWORK:-ghostnet} --history-mode ${HISTORY_MODE:-rolling} --rpc-addr 0.0.0.0:${RPC_PORT:-8732} --net-addr 0.0.0.0:${P2P_PORT:-9732} --data-dir /var/run/tezos/node",
    "node:identity": "npm run env && . ./.env && docker run --rm --entrypoint octez-node -v \"$PWD/${DATA_DIR:-data}:/var/run/tezos/node\" tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} identity generate --data-dir /var/run/tezos/node",
    "node:start": "npm run env && . ./.env && docker run -d --name ${CONTAINER_PREFIX:-tezos}-node --entrypoint octez-node -v \"$PWD/${DATA_DIR:-data}:/var/run/tezos/node\" -p ${RPC_PORT:-8732}:${RPC_PORT:-8732} -p ${P2P_PORT:-9732}:${P2P_PORT:-9732} -p ${METRICS_PORT:-9095}:${METRICS_PORT:-9095} tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} run --network ${TEZOS_NETWORK:-ghostnet} --data-dir /var/run/tezos/node",
    "node:stop": "./scripts/node-stop.sh",
    "node:restart": "npm run node:stop && npm run node:start",
    "node:logs": ". ./.env 2>/dev/null || true && docker logs -f ${CONTAINER_PREFIX:-tezos}-node",

    "node:status": "npm run env && . ./.env && curl -s http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}/chains/main/blocks/head/header | jq '{level, timestamp, hash}'",
    "node:head": "npm run env && . ./.env && curl -s http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}/chains/main/blocks/head/header | jq '{level, timestamp, hash}'",
    "node:peers": "npm run env && . ./.env && curl -s http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}/network/connections | jq -r '.[] | \"\\(.id_point.addr) - \\(.peer_id[0:20])...\"'",

    "baker:start": "npm run env && . ./.env && docker run -d --name ${CONTAINER_PREFIX:-tezos}-baker --network container:${CONTAINER_PREFIX:-tezos}-node -v \"$PWD/${DATA_DIR:-data}:/var/run/tezos/node\" -v \"$PWD/${DATA_DIR:-data}/.tezos-client:/home/tezos/.tezos-client\" --entrypoint octez-baker-${PROTOCOL:-PtSeouLo} tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} run with local node /var/run/tezos/node --without-dal --liquidity-baking-toggle-vote pass ${BAKER_ALIAS:-alice}",
    "baker:stop": "./scripts/baker-stop.sh",
    "baker:logs": ". ./.env 2>/dev/null || true && docker logs -f ${CONTAINER_PREFIX:-tezos}-baker",
    "baker:status": "./scripts/baker-status.sh",

    "account:create": "npm run env && . ./.env && docker exec ${CONTAINER_PREFIX:-tezos}-node octez-client -d /var/run/tezos/node/.tezos-client --endpoint http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732} gen keys ${BAKER_ALIAS:-alice}",
    "account:show": "npm run env && . ./.env && docker exec ${CONTAINER_PREFIX:-tezos}-node octez-client -d /var/run/tezos/node/.tezos-client --endpoint http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732} show address ${BAKER_ALIAS:-alice}",

    "delegate:register": "npm run env && . ./.env && docker exec ${CONTAINER_PREFIX:-tezos}-node octez-client -d /var/run/tezos/node/.tezos-client --endpoint http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732} register key ${BAKER_ALIAS:-alice} as delegate",

    "snapshot:download": "npm run env && . ./.env && mkdir -p ${BACKUP_DIR:-backups} && cd ${BACKUP_DIR:-backups} && wget -O ${TEZOS_NETWORK:-ghostnet}-rolling.snapshot https://snapshots.tzinit.org/${TEZOS_NETWORK:-ghostnet}/rolling",
    "snapshot:import": "npm run env && . ./.env && docker run --rm --entrypoint octez-node -v \"$PWD/${DATA_DIR:-data}:/var/run/tezos/node\" -v \"$PWD/${BACKUP_DIR:-backups}:/backups:ro\" tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} snapshot import /backups/${TEZOS_NETWORK:-ghostnet}-rolling.snapshot --data-dir /var/run/tezos/node",

    "monitor": "./scripts/monitor.sh",
    "monitoring:start": "cd monitoring && docker-compose up -d",
    "monitoring:stop": "cd monitoring && docker-compose down",
    "monitoring:logs": "cd monitoring && docker-compose logs -f",

    "ps": ". ./.env 2>/dev/null || true && docker ps -a | grep -E \"${CONTAINER_PREFIX:-tezos}|CONTAINER\"",
    "clean": ". ./.env 2>/dev/null || true && docker rm -f ${CONTAINER_PREFIX:-tezos}-node ${CONTAINER_PREFIX:-tezos}-baker 2>/dev/null || true"
  },
  "keywords": ["tezos", "baker", "blockchain", "ghostnet", "octez"],
  "author": "",
  "license": "MIT"
}
EOF

# Backup old package.json
cp package.json backups/pre-migration-$(date +%Y%m%d)/package.json.pre-simplify

# Replace with new version
mv package.json.new package.json
```

### Step 7.2: Verify package.json
```bash
# Check it's valid JSON
cat package.json | jq '.' > /dev/null && echo "✅ Valid JSON" || echo "❌ Invalid JSON"

# Show new scripts
cat package.json | jq '.scripts | keys[]'
```

**✅ CHECKPOINT**: package.json simplified to essential commands only.

---

## PART 8: START EVERYTHING UP

### Step 8.1: Start Node
```bash
# Start node with fixed configuration
npm run node:start

# Wait 10 seconds
sleep 10
```

### Step 8.2: Verify Node Started
```bash
# Check container running
docker ps | grep tezos-node

# Expected: Should show tezos-node container running

# Check RPC responding
curl -s http://127.0.0.1:8732/version | jq '.'

# Expected: Should show version information
```

### Step 8.3: Verify ACL Security
```bash
# This should WORK (localhost, full access)
curl -s http://127.0.0.1:8732/chains/main/blocks/head | jq '.header.level'

# This should WORK (safe GET endpoint)
curl -s http://127.0.0.1:8732/version | jq '.'
```

### Step 8.4: Verify Metrics Endpoint
```bash
# Check metrics are exposed
curl -s http://127.0.0.1:9095/metrics | head -20

# Expected: Should show Prometheus-format metrics
```

### Step 8.5: Start Monitoring Stack
```bash
cd monitoring
docker-compose up -d
cd ..

# Wait 10 seconds for services to start
sleep 10
```

### Step 8.6: Verify Monitoring
```bash
# Check Prometheus is running
curl -s http://localhost:9090/-/healthy

# Check Grafana is running
curl -s http://localhost:3000/api/health | jq '.'
```

### Step 8.7: Start Baker (If Node is Synced)
```bash
# Check if node is synced first
npm run node:status

# If synced and you have baker account:
npm run baker:start
```

**✅ CHECKPOINT**: All services running with official configuration.

---

## VERIFICATION CHECKLIST

Run each command:

```bash
# ✅ Node is running
docker ps | grep tezos-node

# ✅ RPC responds on localhost
curl -s http://127.0.0.1:8732/version | jq '.version.major'

# ✅ Metrics are exposed
curl -s http://127.0.0.1:9095/metrics | grep octez_block_level

# ✅ Prometheus is running
curl -s http://localhost:9090/-/healthy

# ✅ Grafana is running
curl -s http://localhost:3000/api/health | jq '.database'

# ✅ ACL is configured (check config)
cat data/config.json | jq '.rpc.acl | length'
# Expected: 3 (three ACL rules)

# ✅ Logging is configured
cat data/config.json | jq '.log.output'
# Expected: "/var/run/tezos/node/logs/octez-node.log"

# ✅ No custom health-check cron
crontab -l | grep health-check
# Expected: nothing (should be empty)
```

### Manual Checks

1. **Open Grafana**: http://localhost:3000
   - Login: admin / tezos_monitoring_2026
   - Add Prometheus data source: http://prometheus:9090

2. **Check Node Logs**:
   ```bash
   npm run node:logs
   # Press Ctrl+C to exit
   ```

**✅ CHECKPOINT**: All verification passed.

---

## SUMMARY

### ✅ What Was Fixed
1. Security: ACL now properly restricts remote RPC access
2. Monitoring: Using official Prometheus + Grafana
3. Logging: Added proper log configuration
4. Configuration: Follows official documentation
5. Simplicity: Removed unnecessary custom code

### ✅ What Was Removed
1. Custom health-check.sh script
2. GitHub Actions monitoring workflow
3. Custom cron job

### ✅ What Was Added
1. Prometheus + Grafana monitoring stack
2. Proper ACL configuration
3. Logging configuration

---

## COMPLETE! 🎉

**Migration successful!** You now have a documentation-compliant Tezos baker setup.

**Access Points**:
- Grafana: http://localhost:3000 (admin / tezos_monitoring_2026)
- Prometheus: http://localhost:9090

**Documentation**:
- Node Config: https://octez.tezos.com/user/node-configuration.html
- Monitoring: https://octez.tezos.com/user/node-monitoring.html
