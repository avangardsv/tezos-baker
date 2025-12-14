# COMPREHENSIVE AI PROMPT: Tezos Baker Testnet Simplification & Setup

**Date**: 2025-12-14
**Purpose**: Complete prompt for less advanced AI to simplify and run Tezos baker on testnet
**Target**: Ghostnet (Tezos testnet) - simple, minimal setup

---

## CURRENT STATE ANALYSIS

### Repository Status
- **Size**: 55MB (target: ~1MB)
- **Files**: 1,124 files (target: 10-15 files)
- **Complexity**: 6/10 (target: 3/10)
- **Migration**: 70% complete (new flat structure exists, old structure not removed)

### What's Already Done ✅
The repository has a NEW simplified flat structure at root level:
- `setup.sh` - One-command setup script
- `start.sh` - One-command start baker
- `stop.sh` - Stop all services
- `status.sh` - Check sync status
- `docker-compose.yml` - All services defined
- `Dockerfile` - Octez build
- `config-ghostnet.json` - Testnet configuration
- `config-mainnet.json` - Mainnet configuration
- `README.md` - Quick start guide
- `ARCHITECTURE.md` - Full documentation (90KB)

### What's Blocking Simplification ❌
1. **agents/** directory - 54MB (98% of repo size) - AI workflow tools
2. **Old directories still present**:
   - `config/` - Old configs (duplicates)
   - `docker/` - Old docker files (duplicates)
   - `scripts/` - Old scripts (replaced by root scripts)
   - `monitoring/` - Optional monitoring configs
   - `security/` - Security guides
   - `docs/` - Multiple doc files

### Current Structure
```
tezos-baker/
├── setup.sh              ✅ NEW (works)
├── start.sh              ✅ NEW (works)
├── stop.sh               ✅ NEW (works)
├── status.sh             ✅ NEW (works)
├── docker-compose.yml    ✅ NEW (works)
├── Dockerfile            ✅ NEW (works)
├── config-ghostnet.json  ✅ NEW (works)
├── config-mainnet.json   ✅ NEW (works)
├── README.md             ✅ NEW
├── ARCHITECTURE.md       ✅ NEW
├── .env.example          ✅ NEW
│
├── agents/               ❌ 54MB - move to separate repo
├── config/               ❌ OLD - delete (duplicates)
├── docker/               ❌ OLD - delete (duplicates)
├── scripts/              ❌ OLD - delete (replaced)
├── monitoring/           ⚠️  OPTIONAL - keep or move to branch
├── security/             ⚠️  OPTIONAL - keep or move to branch
└── docs/                 ❌ OLD - delete (consolidated to ARCHITECTURE.md)
```

---

## YOUR TASK: SIMPLIFY FOR TESTNET USE

### Goal
Create the SIMPLEST possible Tezos baker for Ghostnet (testnet) that:
1. Can be run in 3 commands
2. Has 10-15 files at root level
3. No nested directories (except data/logs created at runtime)
4. Easy for ANY AI to understand
5. Repository size ~1MB

### Strategy: Two Options

---

## OPTION 1: MINIMAL CLEANUP (Recommended - 10 minutes)

**Just run testnet with current structure, ignore the bloat**

### What to Do
```bash
# 1. Create .env file
cp .env.example .env

# Edit .env to set:
TEZOS_NETWORK=ghostnet
BAKER_ALIAS=alice
ENABLE_BAKER=true
ENABLE_ENDORSER=true

# 2. Run setup
./setup.sh ghostnet --skip-snapshot

# 3. Wait for sync (check with):
./status.sh

# 4. Generate keys
docker exec tezos-node tezos-client gen keys alice

# 5. Get testnet XTZ from faucet:
# Visit: https://faucet.ghostnet.teztnets.xyz/
# Enter your address from: docker exec tezos-node tezos-client show address alice

# 6. Start baking
./start.sh alice ghostnet

# 7. Check status
./status.sh
```

### Expected Behavior
- **Setup time**: 1-3 hours (node sync)
- **First baking rights**: 2-3 days after registration
- **Disk usage**: ~20GB for ghostnet data
- **Memory**: ~2GB RAM
- **CPU**: 2+ cores

### Pros
- ✅ Works immediately
- ✅ No file deletion needed
- ✅ Can test before cleanup

### Cons
- ❌ Repository still 55MB
- ❌ Confusing file structure (both old and new)

---

## OPTION 2: COMPLETE SIMPLIFICATION (Recommended for clean state - 30 minutes)

**Delete all bloat, achieve ultra-simple structure**

### Step-by-Step Commands

#### Phase 1: Move agents/ directory (98% size reduction)
```bash
cd /Users/admin/tezos-baker

# Create separate repository for AI agents
mkdir -p ../tezos-baker-ai
mv agents ../tezos-baker-ai/

# Update .gitignore
echo "agents/" >> .gitignore

# Result: 55MB → 1MB
```

#### Phase 2: Remove old duplicate directories
```bash
# IMPORTANT: Only do this AFTER verifying new structure works!

# Test new structure first:
./setup.sh ghostnet --skip-snapshot
docker-compose config  # Validate docker-compose.yml

# If tests pass, remove duplicates:
rm -rf config/
rm -rf docker/
rm -rf scripts/
rm -rf docs/

# Optional: Keep monitoring and security in separate branch
# git checkout -b optional-features
# git add monitoring/ security/
# git commit -m "Move monitoring and security to optional branch"
# git checkout main
rm -rf monitoring/
rm -rf security/
```

#### Phase 3: Verify final state
```bash
# Check file count (should be ~12 files)
ls -1 | wc -l

# Check size (should be ~1MB)
du -sh .

# List files
ls -lh

# Expected output:
# - setup.sh
# - start.sh
# - stop.sh
# - status.sh
# - docker-compose.yml
# - Dockerfile
# - config-ghostnet.json
# - config-mainnet.json
# - .env.example
# - .gitignore
# - README.md
# - ARCHITECTURE.md
```

#### Phase 4: Run testnet
```bash
# Same as Option 1
cp .env.example .env
# Edit .env...
./setup.sh ghostnet
# Wait for sync...
docker exec tezos-node tezos-client gen keys alice
# Fund from faucet...
./start.sh alice ghostnet
./status.sh
```

### Final Structure
```
tezos-baker/
├── .env.example
├── .gitignore
├── ARCHITECTURE.md          # Complete docs (90KB)
├── Dockerfile
├── README.md
├── config-ghostnet.json
├── config-mainnet.json
├── docker-compose.yml
├── setup.sh
├── start.sh
├── status.sh
└── stop.sh

Total: 12 files, ~1MB
```

### Pros
- ✅ 98% smaller repository
- ✅ All files at root level
- ✅ Zero directory nesting
- ✅ Ultra-simple for AI understanding
- ✅ Still has full functionality

### Cons
- ⚠️ Need to test before deleting
- ⚠️ Cannot easily rollback (commit first!)

---

## DETAILED TESTNET WORKFLOW

### Prerequisites
- Docker and Docker Compose installed
- 2+ CPU cores
- 4GB RAM
- 50GB disk space
- Internet connection

### Complete Testnet Setup (Step-by-Step)

#### 1. Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Edit .env with these settings:
nano .env

# Required settings:
TEZOS_NETWORK=ghostnet
BAKER_ALIAS=alice
ENABLE_BAKER=true
ENABLE_ENDORSER=true
OCTEZ_VERSION=v20.2

# Optional monitoring (recommended):
# To enable monitoring dashboards, you'll start with --profile monitoring
```

#### 2. Start Services
```bash
# Without monitoring (minimal):
./setup.sh ghostnet

# OR with monitoring (includes Grafana dashboards):
docker-compose --profile monitoring up -d

# Check services are running:
docker ps

# Should show:
# - tezos-node
# - tezos-baker
# - tezos-endorser
# - (optional) prometheus, grafana, alertmanager
```

#### 3. Wait for Node Sync
```bash
# Check sync status:
./status.sh

# Or monitor continuously:
watch -n 30 './status.sh'

# Node is ready when:
# - "Bootstrapped: yes"
# - "Head lag: 0-2 blocks"

# Expected sync time:
# - Full sync: 6-12 hours
# - With snapshot: 1-3 hours (if you answer 'y' to snapshot prompt in setup.sh)
```

#### 4. Generate Keys
```bash
# Generate a new key pair:
docker exec tezos-node tezos-client gen keys alice

# Get your address:
docker exec tezos-node tezos-client show address alice

# Output will show:
# Hash: tz1... (this is your address)
# Public Key: edpk...
```

#### 5. Fund Account from Testnet Faucet
```bash
# 1. Copy your tz1... address from previous step

# 2. Visit Ghostnet faucet:
#    https://faucet.ghostnet.teztnets.xyz/

# 3. Paste your address and request testnet XTZ

# 4. Wait 1-2 minutes, then check balance:
docker exec tezos-node tezos-client get balance for alice

# Should show: ~6000 ꜩ (testnet tokens)
```

#### 6. Register as Delegate
```bash
# Register alice as a delegate:
docker exec tezos-node tezos-client register key alice as delegate

# Wait for confirmation (1-2 minutes):
sleep 120

# Verify registration:
docker exec tezos-node tezos-client show address alice

# Should show "Registered: yes"
```

#### 7. Start Baking
```bash
# Start baker and endorser:
./start.sh alice ghostnet

# Or manually:
docker-compose up -d tezos-baker tezos-endorser

# Check baker logs:
docker logs -f tezos-baker

# Check endorser logs:
docker logs -f tezos-endorser
```

#### 8. Monitor Operations
```bash
# Quick status:
./status.sh

# Check baking rights (may be empty for first few cycles):
docker exec tezos-node tezos-client rpc get \
  /chains/main/blocks/head/helpers/baking_rights

# Check endorsing rights:
docker exec tezos-node tezos-client rpc get \
  /chains/main/blocks/head/helpers/endorsing_rights

# View Grafana dashboards (if monitoring enabled):
# Open: http://localhost:3000
# Login: admin / change_me_secure (from .env)
```

#### 9. Understanding the Timeline
```
NOW
  │
  ├─ 0min: Start node
  ├─ 1-3hr: Node syncs (with snapshot)
  ├─ Generate keys
  ├─ Fund from faucet
  ├─ Register delegate
  │
  ├─ +5 cycles (~14 days): First baking rights assigned
  ├─ +7 cycles (~20 days): First endorsing rights
  │
  └─ Ongoing: Bake blocks and endorse when you have rights
```

**Important**: On testnet, you might not get baking/endorsing rights immediately. You need to wait 5-7 cycles (2-3 days per cycle = ~14-21 days) before the protocol assigns you rights based on your stake.

---

## TROUBLESHOOTING

### Problem: Node won't sync
```bash
# Check node logs:
docker logs tezos-node

# Common fixes:
# 1. Check internet connection
# 2. Check ports 9732, 8732 are accessible:
docker exec tezos-node netstat -tulpn | grep 9732

# 3. Try importing snapshot:
./scripts/import_snapshot.sh ghostnet  # If script exists

# 4. Restart node:
docker-compose restart tezos-node
```

### Problem: Baker won't start
```bash
# Check baker logs:
docker logs tezos-baker

# Common causes:
# 1. Node not synced yet - wait for sync
# 2. Delegate not registered - register first
# 3. No baking rights yet - normal, wait 5+ cycles

# Verify delegate registration:
docker exec tezos-node tezos-client show address alice
```

### Problem: "Not enough funds" error
```bash
# Check balance:
docker exec tezos-node tezos-client get balance for alice

# Solutions:
# 1. Request more from faucet
# 2. Wait for faucet transaction to confirm
# 3. On mainnet: need 6000+ XTZ
```

### Problem: Docker compose file not found
```bash
# If using old structure:
docker-compose -f docker/compose.ghostnet.yml up -d

# If using new structure:
docker-compose up -d

# Check which file exists:
ls -l docker-compose.yml
ls -l docker/compose.ghostnet.yml
```

---

## COMPLETE COMMAND REFERENCE

### Docker Commands
```bash
# Start all services:
docker-compose up -d

# Start with monitoring:
docker-compose --profile monitoring up -d

# Stop all services:
docker-compose down

# View running containers:
docker ps

# View logs (follow mode):
docker logs -f tezos-node
docker logs -f tezos-baker
docker logs -f tezos-endorser

# Execute commands in container:
docker exec tezos-node <command>

# Restart specific service:
docker-compose restart tezos-node
```

### Tezos Client Commands (inside container)
```bash
# Generate keys:
docker exec tezos-node tezos-client gen keys <alias>

# Import keys:
docker exec tezos-node tezos-client import secret key <alias> <secret_key>

# Show address:
docker exec tezos-node tezos-client show address <alias>

# Get balance:
docker exec tezos-node tezos-client get balance for <alias>

# Register delegate:
docker exec tezos-node tezos-client register key <alias> as delegate

# Check sync:
docker exec tezos-node tezos-client bootstrapped

# Check baking rights:
docker exec tezos-node tezos-client rpc get \
  /chains/main/blocks/head/helpers/baking_rights

# List known addresses:
docker exec tezos-node tezos-client list known addresses
```

### Status Scripts (if they exist)
```bash
# Quick status:
./status.sh

# Setup:
./setup.sh ghostnet

# Start baker:
./start.sh alice ghostnet

# Stop all:
./stop.sh
```

---

## EXPECTED OUTPUTS

### When Node is Syncing
```
Checking node sync status...
Bootstrapped: no
Head level: 4582910
Network level: 4584120
Head lag: 1210 blocks
Status: ⚠️  SYNCING (1210 blocks behind)
```

### When Node is Synced
```
Checking node sync status...
Bootstrapped: yes
Head level: 4584120
Network level: 4584120
Head lag: 0 blocks
Status: ✅ SYNCED
```

### When Baker is Running
```
Starting Tezos baker for alice on ghostnet
Baker started with PID 1234
Endorser started with PID 1235
✅ Both processes running
```

### When You Have Baking Rights
```
[tezos-baker] Baker started for tz1abc...
[tezos-baker] Checking baking rights for alice
[tezos-baker] Found baking rights at level 4584200
[tezos-baker] Baking block at level 4584200
[tezos-baker] Block baked successfully: BLxyz...
```

---

## CONFIGURATION FILES EXPLAINED

### .env (Environment Variables)
```bash
# Network (ghostnet or mainnet)
TEZOS_NETWORK=ghostnet

# Octez version
OCTEZ_VERSION=v20.2

# Baker settings
BAKER_ALIAS=alice
ENABLE_BAKER=true
ENABLE_ENDORSER=true

# Ports
P2P_PORT=9732      # Tezos P2P network
RPC_PORT=8732      # RPC API (localhost only)
METRICS_PORT=9095  # Prometheus metrics

# Monitoring (if enabled)
GRAFANA_PORT=3000
GRAFANA_ADMIN=admin
GRAFANA_PASS=change_me_secure
PROMETHEUS_PORT=9090

# Resource limits
MAX_CONNECTIONS=50
HISTORY_MODE=rolling  # rolling, full, or archive

# Logging
LOG_LEVEL=INFO  # DEBUG, INFO, NOTICE, WARNING, ERROR
```

### docker-compose.yml (Service Definitions)
Defines 3 core services + optional monitoring:

**Core Services (always run):**
1. `tezos-node` - Blockchain node
2. `tezos-baker` - Block creation
3. `tezos-endorser` - Block attestation

**Monitoring Services (optional, use `--profile monitoring`):**
4. `prometheus` - Metrics collection
5. `grafana` - Dashboards
6. `alertmanager` - Alerting
7. `node-exporter` - System metrics

### config-ghostnet.json (Node Configuration)
```json
{
  "data-dir": "/var/lib/tezos",
  "network": "ghostnet",
  "history_mode": "rolling",
  "rpc": {
    "listen-addrs": ["127.0.0.1:8732"]
  },
  "p2p": {
    "bootstrap-peers": [
      "ghostnet.teztnets.xyz:9732",
      "ghostnet.ecadinfra.com:9732"
    ],
    "listen-addr": "0.0.0.0:9732"
  },
  "log": {
    "output": "/var/log/tezos/node.log",
    "level": "info"
  },
  "metrics_addr": ["0.0.0.0:9095"]
}
```

---

## SECURITY NOTES FOR TESTNET

### Testnet (Ghostnet) - Relaxed Security OK
Since testnet tokens have no value:
- ✅ Can use simple passwords
- ✅ Can expose RPC on localhost
- ✅ Can skip hardware wallet
- ✅ Can use HTTP (not HTTPS)
- ✅ Keys stored in container are fine

### If Moving to Mainnet - CRITICAL SECURITY
When using real XTZ:
- ❌ NEVER use same keys as testnet
- ❌ NEVER expose RPC to internet
- ✅ MUST use hardware wallet (Ledger)
- ✅ MUST use strong passwords
- ✅ MUST enable firewall
- ✅ MUST backup keys securely
- ✅ MUST use HTTPS
- ✅ Follow security/hardening_checklist.md

---

## COMPLETE FILE INVENTORY (After Simplification)

### Core Files (Required)
| File | Size | Purpose |
|------|------|---------|
| `docker-compose.yml` | 7KB | Service orchestration |
| `Dockerfile` | 2KB | Octez build instructions |
| `config-ghostnet.json` | 3KB | Testnet node config |
| `config-mainnet.json` | 3KB | Mainnet node config |
| `.env.example` | 5KB | Configuration template |

### Script Files (Convenient)
| File | Size | Purpose |
|------|------|---------|
| `setup.sh` | 3KB | One-command setup |
| `start.sh` | 2KB | Start baker/endorser |
| `stop.sh` | 1KB | Stop all services |
| `status.sh` | 2KB | Check sync status |

### Documentation
| File | Size | Purpose |
|------|------|---------|
| `README.md` | 2KB | Quick start guide |
| `ARCHITECTURE.md` | 90KB | Complete documentation |
| `.gitignore` | 1KB | Git ignore rules |

**Total: 12 files, ~120KB (excluding ARCHITECTURE.md) or ~210KB (including)**

---

## SIMPLIFICATION DECISION MATRIX

Choose your path:

| Goal | Recommended Option | Time | Outcome |
|------|-------------------|------|---------|
| Just test baking ASAP | Option 1 | 10min | Works, but 55MB repo |
| Clean, simple structure | Option 2 | 30min | Perfect, 1MB repo |
| Production mainnet | Option 2 + Security | 4+ hours | Secure, production-ready |

---

## BACKUP & SAFETY

### Before Simplification (Option 2)
```bash
# Create git tag for rollback:
git tag pre-simplification
git push origin pre-simplification

# Or create backup:
cd ..
cp -r tezos-baker tezos-baker-backup
```

### After Simplification
```bash
# Commit cleaned structure:
git add -A
git commit -m "Complete simplification: flat structure, remove bloat"

# If something breaks, rollback:
git reset --hard pre-simplification
```

### Backup Keys (Important!)
```bash
# After generating keys, back them up:
docker exec tezos-node tezos-client show address alice -S

# Copy the secret key somewhere safe!
# On mainnet, NEVER store unencrypted keys!
```

---

## AI ASSISTANT INSTRUCTIONS

If you are a less advanced AI implementing this:

### Your Task
1. **Read this entire document carefully**
2. **Ask user which option they want**: Option 1 (quick test) or Option 2 (clean simplification)
3. **Execute commands step-by-step**
4. **Wait for each command to complete before next**
5. **Show command output to user**
6. **Explain what's happening at each step**
7. **Check for errors after each command**

### Key Rules
- ✅ DO execute commands sequentially
- ✅ DO show user what you're doing
- ✅ DO wait for user confirmation before deleting files
- ✅ DO verify outputs match expected outputs
- ❌ DON'T skip steps
- ❌ DON'T assume commands worked - check logs
- ❌ DON'T delete files without testing first

### Template Responses

**When starting:**
```
I will help you set up Tezos baker on Ghostnet testnet.

I see two options:

Option 1: Quick test (10 min)
- Keep all files as-is
- Run testnet immediately
- Repository stays 55MB

Option 2: Clean simplification (30 min)
- Remove all bloat
- Repository becomes 1MB
- Still fully functional

Which would you prefer?
```

**When executing:**
```
Step 1/9: Creating .env file
Running: cp .env.example .env
✅ Success

Step 2/9: Starting Docker services
Running: docker-compose up -d
[show output]
✅ Services started: tezos-node, tezos-baker, tezos-endorser

Step 3/9: Waiting for node sync...
[continue...]
```

**When something fails:**
```
❌ Error detected in Step 5

Command: docker exec tezos-node tezos-client gen keys alice
Error: Cannot connect to node

Troubleshooting:
1. Checking if node is running...
   docker ps | grep tezos-node

2. Checking node logs...
   docker logs tezos-node | tail -20

[Based on output, suggest fix]
```

---

## VALIDATION CHECKLIST

After setup, verify everything works:

```bash
# ✅ Checklist
[ ] Docker services running: docker ps shows 3+ containers
[ ] Node synced: ./status.sh shows "SYNCED"
[ ] Keys generated: docker exec tezos-node tezos-client list known addresses
[ ] Account funded: docker exec tezos-node tezos-client get balance for alice
[ ] Delegate registered: docker exec tezos-node tezos-client show address alice shows "Registered"
[ ] Baker running: docker logs tezos-baker shows "Baker started"
[ ] Endorser running: docker logs tezos-endorser shows "Endorser started"

# Optional (if monitoring enabled):
[ ] Grafana accessible: http://localhost:3000
[ ] Prometheus accessible: http://localhost:9090
[ ] Metrics being collected: Check Prometheus targets
```

---

## QUICK REFERENCE CARD

### 3-Command Testnet Setup (Minimal)
```bash
./setup.sh ghostnet
docker exec tezos-node tezos-client gen keys alice
# (fund from faucet: https://faucet.ghostnet.teztnets.xyz/)
./start.sh alice ghostnet
```

### Daily Operations
```bash
./status.sh                    # Check health
docker logs -f tezos-baker     # Watch baker
docker logs -f tezos-endorser  # Watch endorser
```

### Stop Everything
```bash
./stop.sh
# OR
docker-compose down
```

---

## ADDITIONAL RESOURCES

### Testnet Faucet
- **Ghostnet**: https://faucet.ghostnet.teztnets.xyz/
- Provides free testnet XTZ
- No registration required
- Instant funding

### Tezos Documentation
- **Octez Documentation**: https://tezos.gitlab.io/
- **Baker Guide**: https://tezos.gitlab.io/introduction/howtorun.html#baker
- **RPC API**: https://tezos.gitlab.io/shell/rpc.html

### Block Explorers (to track your baker)
- **Ghostnet**: https://ghostnet.tzkt.io/
- Search for your tz1... address to see:
  - Balance
  - Delegate status
  - Baking activity
  - Rewards earned

### Monitoring
- Grafana dashboards: http://localhost:3000 (if monitoring enabled)
- Prometheus metrics: http://localhost:9090
- Node metrics: http://localhost:9095/metrics

---

## FINAL NOTES

This prompt contains EVERYTHING needed to:
1. Understand the current repository state
2. Choose simplification approach
3. Set up Ghostnet testnet baker
4. Troubleshoot common issues
5. Monitor operations
6. Verify everything works

**Estimated Total Time:**
- Option 1 (quick): 10 min setup + 1-3 hours sync
- Option 2 (clean): 30 min setup + 1-3 hours sync

**Testnet vs Mainnet:**
- This guide is for TESTNET (Ghostnet) only
- Tokens have NO real value
- Perfect for learning and testing
- For mainnet, follow ARCHITECTURE.md security sections

**Support:**
- Check ARCHITECTURE.md for detailed component documentation
- Check logs: `docker logs <container-name>`
- Check status: `./status.sh`

Good luck! 🚀
