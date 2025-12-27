# Tezos Baker

Run a Tezos validator on Ghostnet testnet. Simple setup, minimal configuration.

## Installation

### Prerequisites

- **Docker** - Container runtime
- **Node.js & npm** - For running npm scripts (optional but recommended)
- **System requirements**: 2+ CPU cores, 4GB RAM, 50GB disk space

### Install Docker (macOS)

**Option 1: Docker Desktop (Recommended)**
1. Download Docker Desktop from https://www.docker.com/products/docker-desktop
2. Install and launch Docker Desktop
3. Verify installation:
```bash
docker --version
docker compose version
```

**Option 2: Homebrew**
```bash
# Install Docker
brew install --cask docker

# Launch Docker Desktop application
# Verify installation
docker --version
docker compose version
```

### Repository Setup

```bash
# Clone and navigate to repository
git clone <your-fork-url> tezos-baker
cd tezos-baker

# Create environment file (customize if needed)
cp .env.example .env
```

## Prerequisites Check (run before starting)

- Docker running:
  ```bash
  docker info
  ```
  Expected: no errors; shows client/server info.
- Disk space available:
  ```bash
  df -h .
  ```
  Expected: at least ~50G free on the filesystem containing the repo.
- Ports free:
  ```bash
  lsof -i :8732 -i :9732 -i :9095
  ```
  Expected: no output. If you see processes listed, stop them or change ports in `.env`.
- Node.js and npm present:
  ```bash
  node --version && npm --version
  ```
  Expected: versions print without errors (any maintained LTS release works).

## ⚠️ Multiple Setup Methods Available - Choose ONE

- **Method 1 (Recommended): npm scripts** — see **Quick Start (Correct Method)** below.
- **Method 2 (Advanced): Direct Docker commands** — see **Alternative: Direct Docker Commands**.
- Legacy shell script flow (`./scripts/*.sh`) is not covered; use one of the two methods above.

## Quick Start (Correct Method)

**⚠️ IMPORTANT**: Rolling mode nodes **require** a snapshot to sync. Without it, you'll get "insufficient history" errors and 0 connections. This is the verified working method:

### Step-by-Step Setup

```bash
# 0. Ensure .env exists (defaults match this guide)
cp .env.example .env

# 1. Initialize node configuration
npm run node:init

# 2. Create version file
npm run node:version

# 3. Download snapshot (mandatory for rolling mode)
npm run snapshot:download
# Wait for 1.6GB download to complete (~3-5 minutes)

# 4. Import snapshot into clean data directory
npm run snapshot:import
# This takes 2-3 minutes, validates blockchain state
# Verify: look for "successful import from file" in the output

# 5. Generate node identity (proof-of-work, ~30 seconds)
npm run node:identity
# Verify: data/identity.json exists

# 6. Start the node
npm run node:start
# Verify: docker ps | grep tezos-node

# 7. Verify syncing (should show peer connections and block progress)
npm run node:logs
# Look for: "synchronizing: current head is Xh old (level: 17000000+)"
# Should see 10+ peer connections within 1-2 minutes

# 8. Wait for node to fully sync (1-2 hours)
# Monitor with: npm run node:logs
# Verify: npm run node:status shows a recent block and advancing

# 9. Create baker account
npm run account:create
npm run account:show

# 10. Fund account with testnet XTZ
# Visit https://faucet.ghostnet.teztnets.xyz/

# 11. Register as delegate
npm run delegate:register

# 12. Start baker
npm run baker:start

# View all commands
npm run help
```

### Why This Order Matters

**The Problem**: Rolling mode nodes only keep recent blocks. Network peers have their "caboose" (oldest retained block) at ~16-17 million. Starting from block 0 causes all peers to reject you with "insufficient history".

**The Solution**: Import a snapshot **before** starting the node. This makes your node start at block ~17M, compatible with network peers.

**Official docs omission**: The Octez documentation shows rolling mode setup but doesn't emphasize that snapshots are **mandatory**, not optional.

## Alternative: Direct Docker Commands (Advanced)

Get your baker running with these commands (snapshot import is mandatory before first start):

```bash
# 1. Initialize node configuration
mkdir -p data
docker run --rm \
  --entrypoint octez-node \
  -v "$PWD/data:/var/run/tezos/node" \
  tezos/tezos:octez-v23.1 \
  config init --network ghostnet --history-mode rolling --rpc-addr 0.0.0.0:8732 --net-addr 0.0.0.0:9732 --data-dir /var/run/tezos/node

# 2. Create version file
docker run --rm \
  --entrypoint sh \
  -v "$PWD/data:/var/run/tezos/node" \
  tezos/tezos:octez-v23.1 \
  -c 'echo "{\"version\": \"3.2\"}" > /var/run/tezos/node/version.json'

# 3. Download latest rolling snapshot (mandatory for rolling mode)
mkdir -p backups
wget -O backups/ghostnet-rolling.snapshot https://snapshots.tzinit.org/ghostnet/rolling

# 4. Import snapshot into clean data directory
docker run --rm \
  --entrypoint octez-node \
  -v "$PWD/data:/var/run/tezos/node" \
  -v "$PWD/backups:/backups:ro" \
  tezos/tezos:octez-v23.1 \
  snapshot import /backups/ghostnet-rolling.snapshot --data-dir /var/run/tezos/node
# Verify: "successful import from file" appears

# 5. Generate node identity (run after snapshot import)
docker run --rm \
  --entrypoint octez-node \
  -v "$PWD/data:/var/run/tezos/node" \
  tezos/tezos:octez-v23.1 \
  identity generate --data-dir /var/run/tezos/node

# 6. Start the node
docker run -d --name tezos-node \
  --entrypoint octez-node \
  -v "$PWD/data:/var/run/tezos/node" \
  -p 8732:8732 -p 9732:9732 -p 9095:9095 \
  tezos/tezos:octez-v23.1 \
  run --network ghostnet --data-dir /var/run/tezos/node

# 7. Wait for node to bootstrap (1-3 hours with snapshot)
# Monitor with: docker logs -f tezos-node
# Check if bootstrapped:
docker exec tezos-node octez-client --endpoint http://127.0.0.1:8732 bootstrapped

# 8. Generate keys and fund account
docker exec tezos-node octez-client --endpoint http://127.0.0.1:8732 gen keys alice
docker exec tezos-node octez-client --endpoint http://127.0.0.1:8732 show address alice
# Visit https://faucet.ghostnet.teztnets.xyz/ to fund your address

# 9. Register as delegate
docker exec tezos-node octez-client --endpoint http://127.0.0.1:8732 register key alice as delegate

# 10. Start baker
docker run -d --name tezos-baker \
  --network container:tezos-node \
  -v "$PWD/data:/var/run/tezos/node" \
  --entrypoint octez-baker-PtSeouLo \
  tezos/tezos:octez-v23.1 \
  run with local node /var/run/tezos/node alice
```

## Understanding the Commands

### ACL Filtering Fix

If you get "ACL filtering" errors when running `octez-client bootstrapped`, update your `data/config.json`:

```json
{ "data-dir": "/var/run/tezos/node",
  "rpc": {
    "listen-addrs": [ "0.0.0.0:8732" ],
    "acl": [
      {
        "address": "0.0.0.0",
        "blacklist": []
      }
    ]
  },
  "p2p": {
    "bootstrap-peers": [
      "ghostnet.teztnets.com",
      "ghostnet.tzinit.org",
      "ghostnet.tzboot.net",
      "ghostnet.boot.ecadinfra.com",
      "ghostnet.stakenow.de:9733"
    ],
    "listen-addr": "0.0.0.0:9732"
  },
  "shell": { "history_mode": "rolling" },
  "network": "ghostnet"
}
```

## Concepts

### What is Baking?

Baking is the process of creating new blocks on the Tezos blockchain. As a baker, you:
- **Bake blocks** when selected by the protocol
- **Endorse blocks** created by other bakers
- **Earn rewards** for successful operations

### Timeline

```
Setup (10 min)
  ↓
Node Sync (1-3 hours)
  ↓
Account Setup (5 min)
  ↓
Registration (1 min)
  ↓
Wait for Rights (~14-21 days)
  ↓
Start Baking & Earning
```

**Important**: You won't receive baking rights immediately. The protocol assigns rights based on stake over 5-7 cycles (~14-21 days).

### Testnet vs Mainnet

This setup is for **Ghostnet testnet only**:
- ✅ Tokens have no real value
- ✅ Safe to experiment
- ✅ Keys stored in container (fine for testnet)
- ❌ **NOT suitable for mainnet** (requires hardware wallet, security hardening)

---

## Security

⚠️ **Testnet:** Current RPC is open (0.0.0.0) - acceptable for testing
❌ **Mainnet:** Open RPC is dangerous - configure strict ACL before production

### Quick Security Check

```bash
# Configure RPC ACL (Interactive)
npm run security:configure-acl

# Verify production readiness
npm run verify
```

### Mainnet Security Requirements

**Essential for mainnet:**
- RPC ACL: Localhost only or whitelist specific IPs
- Firewall: Enabled (block RPC port 8732 externally)
- Baker keys: Hardware wallet (Ledger) or remote signer
- SSH: Key-based authentication only
- Monitoring: Alerts for downtime/missed slots

**Example secure RPC config:**
```json
{
  "rpc": {
    "listen-addrs": ["127.0.0.1:8732"]  // Localhost only
  }
}
```

---

## After Reboot / System Restart

When you restart your laptop, Docker containers stop automatically. Use this single command to restart everything:

```bash
npm start
```

**What it does:**
1. Cleans up stopped containers
2. Starts Tezos node
3. Waits for node initialization
4. Checks for baking rights
5. Starts baker automatically (if you have baking rights)

**Manual steps (if preferred):**
```bash
# 1. Start node
npm run node:start

# 2. Wait 10 seconds for node to initialize
sleep 10

# 3. Check if you have baking rights
npm run baker:status

# 4. If you have baking rights, start baker
npm run baker:start

# 5. Verify everything is running
npm run ps
npm run monitor
```

**Quick verification:**
```bash
npm run monitor          # Shows current sync status
npm run baker:status     # Shows if baker is ready
docker ps                # Shows running containers
```

---

## API Reference

### npm Scripts Reference

```bash
# Quick Start
npm start                    # Start everything after reboot (recommended)

# Setup & Initialization
npm run setup                # Initialize node configuration and identity
npm run setup:snapshot       # Setup + download snapshot

# Node Management
npm run node:start           # Start the node
npm run node:stop            # Stop the node
npm run node:restart         # Restart the node
npm run node:logs            # View node logs
npm run node:status          # Check current block
npm run node:bootstrap       # Wait for bootstrap

# Snapshot Operations
npm run snapshot:download    # Download latest Ghostnet snapshot
npm run snapshot:import      # Import downloaded snapshot

# Account Management
npm run account:create       # Create new account (alice)
npm run account:show         # Show account address
npm run account:balance      # Check account balance

# Delegation & Baking
npm run delegate:register    # Register as delegate
npm run baker:start          # Start baker
npm run baker:stop           # Stop baker
npm run baker:logs           # View baker logs
npm run baker:status         # Check baker registration & rights status
npm run baker:rights         # Check upcoming baking rights

# Monitoring & Diagnostics
npm run monitor              # Show node status dashboard
npm run monitor:watch        # Auto-refreshing dashboard
npm run verify               # Production readiness check
npm run block:inspect        # Inspect block contents

# Security
npm run security:configure-acl  # Interactive RPC ACL configuration

# Utilities
npm run ps                   # Show all Tezos containers
npm run clean                # Stop all containers
npm run clean:data           # Stop all + delete data
npm run help                 # List all commands
```

### Direct Octez Client Commands

For advanced operations, run commands inside the `tezos-node` container:

```bash
# Generate keys
docker exec tezos-node octez-client --endpoint http://127.0.0.1:8732 gen keys <alias>

# Show address
docker exec tezos-node octez-client --endpoint http://127.0.0.1:8732 show address <alias>

# Check balance
docker exec tezos-node octez-client --endpoint http://127.0.0.1:8732 get balance for <alias>

# Register as delegate
docker exec tezos-node octez-client --endpoint http://127.0.0.1:8732 register key <alias> as delegate

# Check sync status
docker exec tezos-node octez-client --endpoint http://127.0.0.1:8732 bootstrapped

# Check baking rights
docker exec tezos-node octez-client --endpoint http://127.0.0.1:8732 rpc get \
  /chains/main/blocks/head/helpers/baking_rights
```

### Docker Commands

```bash
# View running containers
docker ps

# View logs
docker logs -f tezos-node
docker logs -f tezos-baker
docker logs -f tezos-endorser

# Restart service
docker compose restart tezos-node

# Stop all services
docker compose down
```

## Troubleshooting

### ACL Filtering Error

**Symptoms**: `Error: The server doesn't authorize this endpoint (ACL filtering)`

**Cause**: The node's RPC server is in "Secure" mode, blocking certain endpoints like `/monitor/bootstrapped`.

**Solution**: Add an ACL policy to your `data/config.json`:
```json
{
  "rpc": {
    "listen-addrs": [ "0.0.0.0:8732" ],
    "acl": [
      {
        "address": "0.0.0.0",
        "blacklist": []
      }
    ]
  }
}
```

Then restart the node:
```bash
docker rm -f tezos-node
# Run the start node command again
```

### Node Won't Sync / "Insufficient History" Errors

**Symptoms**:
- Node logs show: `disconnected from peer: insufficient history`
- Connection count stuck at 0 or very low
- Node stuck at genesis (level 0) or not progressing
- Logs repeat: `too few connections (conn.: 0)`

**Root Cause**:
Rolling mode nodes only keep recent blocks (their "caboose" is at ~block 16-17M). Your fresh node at block 0 is incompatible with network peers who have already pruned those old blocks. This is **by design**, not a bug.

**Why This Happens**:
1. You start a rolling node from genesis (block 0)
2. Network peers in rolling mode have caboose at block ~16,999,000
3. When peers discover your node needs blocks from 0, they disconnect
4. Result: 0 connections, no syncing

**Verified Solution** (from our investigation):

```bash
# 1. Stop the node
npm run node:stop

# 2. Clean data directory
npm run clean:data

# 3. Initialize config and version
npm run node:init
npm run node:version

# 4. Download snapshot (1.6GB, takes 3-5 minutes)
npm run snapshot:download

# 5. Import snapshot (takes 2-3 minutes)
npm run snapshot:import
# You should see: "successful import from file" and block level ~17,000,000

# 6. Generate identity
rm -f data/identity.json  # Remove any cached identity
npm run node:identity

# 7. Start node
npm run node:start

# 8. Verify success
npm run node:logs
# Look for:
#   - "fetching branch of 19000+ blocks from peer"
#   - "synchronizing: current head is Xh old (level: 17000000+)"
#   - Connection count increasing: conn.: 1 → 8 → 13+
#   - NO more "insufficient history" from majority of peers
```

**Expected Results After Fix**:
- Within 1 minute: 10+ peer connections
- Within 2 minutes: Active syncing from block ~17M
- Within 1-2 hours: Fully synced to current head

**Alternative: Switch to Full Mode** (not recommended - slower):
```bash
# Edit .env file
HISTORY_MODE=full

# Reinitialize
npm run clean:data
npm run setup
npm run node:start
```

Full mode can sync from genesis but requires more disk space and is slower.

### Baker Won't Start

**Symptoms**: Baker container running but no process

**Common causes**:
1. Node not synced - wait for sync first
2. Delegate not registered - run `npm run delegate:register` then restart baker
3. No baking rights yet - normal, wait 5+ cycles

**Check**:
```bash
docker logs tezos-baker
docker exec tezos-node octez-client show address alice
```

### Baker Deactivated

**Symptoms**:
- `npm run baker:status` shows `"deactivated": true`
- No baking rights despite waiting 5+ cycles
- Baker was working before but stopped

**Cause**:
Bakers are automatically deactivated if they don't participate in attestations during their grace period (~5 cycles). This commonly happens when:
- Baker was registered but node went offline for extended period
- Node was syncing during the grace period
- Baker process wasn't running when you had attestation rights

**Solution - Re-register as Delegate**:

```bash
# 1. Verify baker is deactivated
curl -s "http://127.0.0.1:8732/chains/main/blocks/head/context/delegates/tz1YourAddress" | jq '{deactivated, grace_period}'

# 2. Ensure node is fully synced
npm run monitor  # Check timestamp is recent

# 3. Re-register
npm run delegate:register

# 4. Verify re-activation (wait 30 seconds)
curl -s "http://127.0.0.1:8732/chains/main/blocks/head/context/delegates/tz1YourAddress" | jq '{deactivated, grace_period}'
# Should show: "deactivated": false

# 5. Restart baker
npm run baker:stop
npm run baker:start
```

**After re-registration**: You'll need to wait another ~5 cycles for new baking rights to be assigned.

---

### Wallet Not Found / "no public key hash alias" Error

**Symptoms**:
```
Error: no public key hash alias named alice
```

**Cause**: The `octez-client` commands don't specify the wallet data directory location.

**Solution**: Already fixed in current `package.json`. If you see this error, ensure your npm scripts include the `-d /var/run/tezos/node/.tezos-client` flag:

```json
{
  "account:show": "... octez-client -d /var/run/tezos/node/.tezos-client --endpoint ..."
}
```

**Manual check**:
```bash
# This should work
docker exec tezos-node octez-client -d /var/run/tezos/node/.tezos-client list known addresses

# This will fail (missing -d flag)
docker exec tezos-node octez-client list known addresses
```

---

### No Funds

**Symptoms**: Balance shows 0

**Solution**:
- Request from [Ghostnet Faucet](https://faucet.ghostnet.teztnets.xyz/)
- Wait 1-2 minutes for transaction to confirm
- Verify: `npm run account:balance`

### Container Errors

**Symptoms**: Containers won't start

**Solutions**:
```bash
# Check Docker is running
docker info

# Rebuild containers
docker compose build

# Check logs
docker compose logs
```

### Starting Fresh (Complete Reset)

```bash
# Stop all containers with 'tezos' in the name
docker rm -f $(docker ps -aq --filter name=tezos)

# Remove all data
npm run clean:data

# Remove downloaded snapshots
rm -rf backups/*

# Start over from Quick Start step 1
```

## Production Readiness

This section outlines the gap between the current Ghostnet testnet setup and a production-ready mainnet deployment.

### ✅ Already Production-Ready

**Scripts & Automation:**
- Complete npm script suite for all operations
- Automated startup after reboot (`npm start`)
- Comprehensive monitoring and status checking
- Troubleshooting documentation and recovery procedures

**Infrastructure:**
- Docker containerization
- Rolling history mode (efficient disk usage)
- Resource limits configured
- Health checks implemented
- Backup directory structure

### ⚠️ Critical Changes for Mainnet

#### 1. Network Configuration
```bash
# .env changes:
TEZOS_NETWORK=mainnet
PROTOCOL=PtSeouLo  # (or current mainnet protocol)
```

#### 2. Hardware Security Module (REQUIRED)
**Current:** Software wallet in container (testnet only)
**Production:** Ledger hardware wallet required

```bash
USE_LEDGER=true
LEDGER_PATH=/dev/hidraw0
```

**Why critical:** Software wallets are vulnerable to compromise. Mainnet requires Ledger Nano X/S for key security.

#### 3. Minimum Stake
- **Testnet:** 11,999 ꜩ (free testnet tokens)
- **Mainnet:** 6,000+ XTZ minimum
- **Current value:** ~$22,000-30,000 USD (varies with XTZ price)

#### 4. Infrastructure: 24/7 Uptime Required
**Current:** Running on laptop (sleeps, closes, offline)
**Production:** Dedicated server with 99.9%+ uptime

**Options:**
- **VPS:** $20-80/month (DigitalOcean, Linode, Vultr, Hetzner)
  - Specs: 4+ cores, 8GB+ RAM, 200GB+ SSD
- **Bare Metal:** $50-150/month (better performance)
- **Home Server:** $500-1000 one-time + UPS ($100-200)
  - Requires reliable internet, static IP, UPS for power protection

#### 5. RPC Security Hardening
```json
// Current (testnet - open access):
"rpc": {
  "listen-addrs": ["0.0.0.0:8732"],
  "acl": [{"address": "0.0.0.0", "blacklist": []}]
}

// Production (localhost only):
"rpc": {
  "listen-addrs": ["127.0.0.1:8732"],
  "acl": [{"address": "127.0.0.1", "blacklist": []}]
}
```

#### 6. Firewall Configuration
```bash
# Allow only:
# - SSH (port 22): Your IP only
# - P2P (port 9732): Anywhere (required for baking)
# - RPC (port 8732): BLOCK external (localhost only)
```

#### 7. Remote Signer (Recommended)
Separate baker (hot) from keys (cold):
- **Baker server:** Runs node/baker, no keys
- **Signer server:** Holds Ledger, signs operations
- Communication over SSH tunnel or VPN

**Benefit:** Even if baker server is compromised, keys remain safe.

### 🔧 Production Hardening Checklist

**Security:**
- [ ] Ledger hardware wallet purchased and set up
- [ ] Remote signer configured (optional but recommended)
- [ ] SSH key-only authentication (disable password)
- [ ] Firewall rules configured (ufw/iptables)
- [ ] RPC ACL restricted to 127.0.0.1
- [ ] Fail2ban installed (brute force protection)
- [ ] OS security updates automated

**Monitoring & Alerts:**
- [ ] Prometheus + Grafana dashboard
- [ ] Alert notifications (Slack/email/PagerDuty)
- [ ] Monitor: node sync, baker health, balance, missed attestations
- [ ] External uptime monitoring (UptimeRobot, etc.)

**Backup & Recovery:**
- [ ] Automated wallet backup (encrypted)
- [ ] Identity and config backup
- [ ] Recovery procedure tested
- [ ] Backups stored offsite (encrypted S3/private repo)

**Operational:**
- [ ] VPS/server with 99.9%+ uptime SLA
- [ ] DNS name for server (easier management)
- [ ] Log rotation configured
- [ ] Disk space monitoring and alerts
- [ ] Resource usage alerts (CPU/RAM/disk)

### 💰 Cost Estimate

**One-time:**
- XTZ stake: $22,000-30,000 (6,000 XTZ minimum)
- Ledger Nano X: $150
- Setup time: 2-3 days

**Monthly:**
- VPS: $20-80
- Monitoring (optional): $0-20
- **Total:** $20-100/month

**Expected Returns:**
- Baking rewards: ~5-6% APY on stake
- On 6,000 XTZ: ~300 XTZ/year (~$1,050-1,500/year)
- Monthly: ~$90-125
- **Net profit after costs:** ~$50-100/month

### 🎯 Production Migration Path

**Phase 1: Validate on Ghostnet** (Current)
- ✅ Scripts tested and working
- ✅ Node sync working
- ✅ Baker registration successful
- 🔄 Waiting for first attestations/baking (proof of concept)

**Phase 2: Security Hardening** (2-3 days)
- Purchase Ledger Nano X
- Set up VPS with firewall rules
- Configure remote signer (if using)
- Test Ledger integration on Ghostnet
- Document disaster recovery procedures

**Phase 3: Mainnet Preparation** (1-2 weeks)
- Acquire 6,000+ XTZ
- Transfer to Ledger wallet
- Update .env for mainnet
- Deploy to production VPS
- Import mainnet snapshot
- Set up monitoring/alerting

**Phase 4: Go Live** (Day 1)
- Register as mainnet delegate
- Start baker
- Monitor continuously for 24 hours
- Wait ~5 cycles (15 days) for baking rights

**Phase 5: Ongoing Operations**
- Daily: `npm run monitor`
- Weekly: Review logs, check balance
- Monthly: Review performance, update software

### ⚠️ Key Risks

1. **Deactivation:** Missing attestations = automatic deactivation (lose rewards, must re-register)
2. **Server downtime:** Each hour offline = missed attestations
3. **Key loss:** Lose Ledger seed phrase = lose all staked XTZ (BACKUP SEED PHRASE!)
4. **Capital requirement:** Need $22k-30k in XTZ for minimum stake
5. **Protocol changes:** Future protocols may add slashing (currently no slashing on Tezos)

### 📊 Production Readiness Gap

| Component | Current State | Production Ready | Gap |
|-----------|---------------|------------------|-----|
| Scripts | ✅ Complete | ✅ | None |
| Node | ✅ Running (laptop) | ⚠️ Need VPS | Medium |
| Baker | ✅ Running | ⚠️ Need 24/7 uptime | Medium |
| Wallet | ✅ Software | ❌ Need Ledger | **Critical** |
| Security | ⚠️ Basic | ❌ Need hardening | **High** |
| Monitoring | ✅ Manual scripts | ⚠️ Need automated alerts | Medium |
| Backup | ⚠️ Manual | ❌ Need automated | High |
| Network | ✅ Ghostnet | ⚠️ Need mainnet config | Low (config only) |
| Stake | ✅ Testnet tokens | ❌ Need 6,000 XTZ | **Critical** |

**Overall Production Readiness: ~60%**

**Time to Production:** 2-4 weeks (assuming capital available)

**Next Steps for Mainnet:**
1. Order Ledger Nano X (~$150, 1 week delivery)
2. Choose VPS provider, provision server (~$20-80/month)
3. Set up Ledger, test on Ghostnet first
4. Acquire XTZ stake (6,000+ XTZ)
5. Deploy to mainnet with security hardening

---

## Configuration

All settings are in `.env`.

- **Required for npm scripts**:
  - `TEZOS_NETWORK=ghostnet`
  - `OCTEZ_VERSION=octez-v23.1`
- `PROTOCOL=PtSeouLo`
  - `CONTAINER_PREFIX=tezos`
  - `DATA_DIR=./data`
  - `BACKUP_DIR=./backups`
  - `RPC_PORT=8732`
  - `RPC_ADDR=127.0.0.1`
  - `P2P_PORT=9732`
  - `METRICS_PORT=9095`
  - `BAKER_ALIAS=alice`
  - `HISTORY_MODE=rolling`
- **Optional / advanced (not used by npm scripts)**: monitoring, backups, Ledger, remote signer, and alerting variables in `podman-compose.yml`. Set them only if you enable those profiles.

## Resources

- **Testnet Faucet**: https://faucet.ghostnet.teztnets.xyz/
- **Block Explorer**: https://ghostnet.tzkt.io/
- **Octez Documentation**: https://tezos.gitlab.io/
- **Tezos Community**: https://tezos.com/community
- **Snapshots**: https://snapshots.tzinit.org/ghostnet/rolling

## Next Steps

After your baker is running:

1. **Monitor operations**: Use `npm run node:logs` regularly
2. **Watch logs**: `docker logs -f tezos-baker`
3. **Track on explorer**: Search your address on [ghostnet.tzkt.io](https://ghostnet.tzkt.io/)
4. **Wait for rights**: First baking rights appear after ~14-21 days

---

## Investigation Notes: Rolling Mode & Snapshots

This section documents our investigation into why rolling mode setup from the official Octez documentation doesn't work without additional steps.

### The Official Documentation Gap

The [Octez documentation](https://octez.tezos.com/docs/introduction/howtoget.html) shows how to initialize a rolling mode node:

```bash
octez-node config init --network ghostnet --history-mode rolling
octez-node identity generate
octez-node run
```

**What's missing**: Clear emphasis that rolling mode **requires** a snapshot import before first run.

### Technical Root Cause

**The Caboose Problem**:
- Rolling nodes only keep recent blocks (saves disk space)
- The "caboose" is the oldest block a rolling node retains
- Network peers on Ghostnet have their caboose at ~block 16,999,000 (as of Dec 2025)
- A fresh rolling node starts at block 0 (genesis from Jan 2022)
- When peers discover your node needs blocks older than their caboose, they disconnect with "insufficient history"

**Why Full Mode Works**:
Full mode nodes keep all blocks, so they can serve old blocks to new peers. They're rare but exist.

**Why Rolling Mode Fails Without Snapshot**:
- Most network peers are in rolling mode (efficient)
- Your node at block 0 is incompatible with their caboose at 16M+
- Result: No stable peer connections, no syncing

### Our Investigation Process

1. **Started with official docs** - followed exactly, got "insufficient history" errors
2. **Checked GitHub issues** - found issue #87 documenting this behavior
3. **Found GitLab MR #1248** - explains caboose mechanism design
4. **Verified network is operational** - used public RPC, confirmed at block 17M+
5. **Downloaded and imported snapshot** - jumped to block 16,999,557
6. **Result**: Node connected to 13+ peers and synced successfully

### Verified Working Method

See "Quick Start (Correct Method)" section above for the complete, verified procedure.

### References

- **GitHub Issue #87**: Rolling node sync problems
- **GitLab MR #1248**: Caboose mechanism implementation
- **Snapshot Source**: https://snapshots.tzinit.org/ghostnet/rolling
- **Block Explorer**: https://ghostnet.tzkt.io/ (verify current network height)
