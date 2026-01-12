# Tezos Baker - Study Mode

Quick start guide for learning Tezos baking on Ghostnet testnet.

## ⚠️ Educational Project - Not for Production

**This is a learning project for Ghostnet testnet only.**

- ✅ **Use for:** Understanding Tezos baking fundamentals, experimenting on testnet
- ❌ **DO NOT use for:** Mainnet production, securing real funds
- 🏭 **For production:** Use [TezBake](https://docs.tez.capital/tezbake/) with hardware wallet security

**Key limitations:**
- Uses software keys (not hardware wallet)
- No high watermark (HWM) protection
- No consensus key separation
- No failover mechanism
- Designed for Mac laptop (not 24/7 server)

**What you'll learn:**
- Docker container orchestration for Tezos
- Node synchronization and snapshot management
- Staking and delegation mechanics
- Baker daemon operation
- DAL (Data Availability Layer) setup
- Monitoring with Prometheus/Grafana
- Troubleshooting and recovery procedures

## Prerequisites

- **Docker** installed and running
- **Node.js & npm** (optional but recommended)
- **System requirements:** 2+ CPU cores, 4GB RAM, 50GB disk space
- **.env file** configured (copy from `.env.example`)

## Quick Start (5 Minutes)

**⚠️ IMPORTANT:** Rolling mode nodes **require** a snapshot to sync. Without it, you'll get "insufficient history" errors.

### 1. Setup Node

```bash
# Initialize node configuration
npm run setup

# Download snapshot (mandatory for rolling mode, ~1.6GB)
npm run snapshot:download

# Import snapshot (stop node first if running)
npm run snapshot:import

# Start node
npm run node:start
```

### 2. Create Account

```bash
# Create baker account
npm run account:create
npm run account:show

# Get testnet XTZ from faucet
# Visit: https://faucet.ghostnet.teztnets.xyz/
```

### 3. Activate Baker

```bash
# Register as delegate
npm run delegate:register

# ⚠️ CRITICAL: Stake funds (required for baking rights!)
npm run stake:all

# Start baker
npm run baker:start
```

**Timeline:** Wait 14-21 days after staking to receive baking rights.

## DAL Setup (Optional - Advanced)

**DAL (Data Availability Layer)** enables earning additional attestation rewards. This is optional for study mode.

### When to Enable DAL

- Your baker is already attesting successfully
- You see "Missed DAL attestation rewards" on [ghostnet.tzkt.io](https://ghostnet.tzkt.io/)
- You want to maximize testnet rewards

### Quick DAL Setup

```bash
# One-command setup (initializes, starts, and configures baker)
npm run dal:setup
```

**What this does:**
1. Initializes DAL node configuration
2. Starts DAL node container
3. Reconfigures baker to use DAL

### DAL Management Commands

```bash
# Verify DAL is working
npm run dal:verify

# Check DAL status
npm run dal:status

# View DAL logs
npm run dal:logs

# Restart DAL node
npm run dal:restart
```

### Verify DAL Attestations

After setup, check baker logs for DAL attestations:

```bash
npm run baker:logs | grep "with DAL"
```

**Normal output:** `injected attestation (with DAL)`

**Note:** You'll only see DAL attestations when you're assigned DAL shards (random, like baking rights). Seeing "without DAL" is normal when you don't have shard assignments.

## ⚠️ Critical: Staking Required

**You MUST stake funds to receive baking rights!**

- Staking is **mandatory** - unstaked balance won't earn baking rights
- Run `npm run stake:all` after funding your account
- Check status: `npm run stake:status`
- Rights appear 14-21 days after staking

**See:** [docs/STAKING-GUIDE.md](docs/STAKING-GUIDE.md) for detailed explanation.

## Essential Commands

### Quick Reference

| Category | Command | Purpose |
|----------|---------|---------|
| **Setup** | `npm run setup` | Initialize node (init+identity+version) |
| | `npm run snapshot:download` | Download blockchain snapshot |
| | `npm run snapshot:import` | Import snapshot to node |
| **Node** | `npm run node:start` | Start node |
| | `npm run node:stop` | Stop node |
| | `npm run node:restart` | Restart node |
| | `npm run node:hard-restart` | Stop and start node |
| | `npm run node:status` | Check node health |
| | `npm run node:logs` | View live logs |
| | `npm run node:logs:tail` | View last 50 lines |
| | `npm run node:health` | Health metrics |
| | `npm run node:sync-status` | Sync progress |
| **Account** | `npm run account:create` | Generate baker keys |
| | `npm run account:show` | Show address |
| | `npm run account:balance` | Check balance |
| **Staking** | `npm run stake:status` | Check staking status |
| | `npm run stake:all` | Stake all available funds |
| **Baker** | `npm run delegate:register` | Register as delegate |
| | `npm run baker:start` | Start baker daemon |
| | `npm run baker:stop` | Stop baker |
| | `npm run baker:restart` | Restart baker |
| | `npm run baker:hard-restart` | Stop and start baker |
| | `npm run baker:logs` | View live logs |
| | `npm run baker:logs:tail` | View last 50 lines |
| | `npm run baker:enable-dal` | Reconfigure baker with DAL |
| **DAL** | `npm run dal:setup` | Complete DAL setup |
| | `npm run dal:init` | Initialize DAL config |
| | `npm run dal:start` | Start DAL node |
| | `npm run dal:stop` | Stop DAL node |
| | `npm run dal:restart` | Restart DAL node |
| | `npm run dal:verify` | Verify DAL working |
| | `npm run dal:status` | Check DAL health |
| | `npm run dal:logs` | View live logs |
| | `npm run dal:logs:tail` | View last 50 lines |
| **Status** | `npm run status:all` | Show all services status |
| | `npm run status:containers` | List Docker containers |
| | `npm run status:sleep` | Check Mac sleep mode |
| **Monitoring** | `npm run monitoring:start` | Start Grafana/Prometheus |
| | `npm run monitoring:stop` | Stop monitoring stack |
| **Utility** | `npm run restart:all` | Restart all services |
| | `npm run prevent-sleep` | Prevent Mac sleep |
| | `npm run help` | Show help message |

**Full workflow:** setup → snapshot → node → account → stake → delegate → baker → (optional: DAL)

**Note:** Some internal commands (`node:init`, `node:identity`, `node:version`, `env`) are called automatically by other scripts and rarely need to be run directly.

## Quick Health Check

Check if your baker is healthy:

```bash
curl -s http://localhost:9095/metrics | grep -E "p2p_connections_active|is_bootstrapped|head_level"
```

**Healthy output:**
- Connections: 10-30
- Bootstrapped: 1.000000 (means YES)
- Level: Should be close to latest block

**For detailed monitoring:** See [docs/MONITORING-GUIDE.md](docs/MONITORING-GUIDE.md)

## Common Issues

**Node not syncing?**
- Wait for bootstrap (can take hours without snapshot)
- Check connections: `curl -s http://localhost:9095/metrics | grep p2p_connections`
- Need 10+ connections

**Baker not producing blocks?**
- Check staking: `npm run stake:status` (must have staked balance)
- Wait 14-21 days after staking for rights
- Verify delegation: `npm run account:show`

**Container errors?**
- Check .env file exists and is configured
- Verify ports available: `docker ps` (8732, 9732 shouldn't conflict)
- Check logs: `npm run node:logs`

**ACL filtering errors?**
- Edit `data/config.json` and add ACL section (see Troubleshooting below)
- Or restart node: `npm run node:stop && npm run node:start`

**More help:** See [Troubleshooting](#troubleshooting) section below.

## Troubleshooting

### ACL Filtering Error

**Symptoms:** `Error: The server doesn't authorize this endpoint (ACL filtering)`

**Fix:** Edit `data/config.json`:

```json
{
  "rpc": {
    "listen-addrs": ["0.0.0.0:8732"],
    "acl": [
      {
        "address": "0.0.0.0",
        "blacklist": []
      }
    ]
  }
}
```

Then restart: `npm run node:stop && npm run node:start`

### Node Won't Sync / "Insufficient History"

**Cause:** Rolling mode requires snapshot import before first start.

**Solution:**
1. Stop node: `npm run node:stop`
2. Import snapshot: `npm run snapshot:import`
3. Restart: `npm run node:start`

**Why:** Rolling nodes only keep recent blocks. Network peers have "caboose" at ~block 16-17M. Starting from block 0 causes peers to disconnect.

### Baker Won't Start

**Common causes:**
1. Node not synced - wait for sync first
2. Delegate not registered - run `npm run delegate:register`
3. No baking rights yet - normal, wait 5+ cycles (14-21 days)

**Check:**
```bash
docker logs tezos-baker
npm run stake:status
```

### Baker Deactivated

**Symptoms:**
- Baker shows `"deactivated": true` in status
- No baking rights despite waiting 5+ cycles
- Baker was working before but stopped

**Cause:** Bakers are automatically deactivated if they miss attestations during their grace period (~5 cycles). Common reasons:
- Node went offline for extended period
- Baker process wasn't running when you had rights

**Solution:**
```bash
# 1. Ensure node is fully synced
npm run node:logs

# 2. Re-register as delegate
npm run delegate:register

# 3. Restart baker
docker restart tezos-baker

# 4. Wait another 5+ cycles for new baking rights
```

### Wallet Not Found Error

**Symptoms:** `Error: no public key hash alias named alice`

**Cause:** Octez-client can't find wallet data directory.

**Solution:** Already fixed in current npm scripts. If you see this error:
```bash
# Verify wallet exists
docker exec tezos-node octez-client -d /var/run/tezos/node/.tezos-client list known addresses

# If empty, recreate account
npm run account:create
```

### No Funds

**Symptoms:** Balance shows 0 ꜩ

**Solution:**
1. Get tokens from [Ghostnet Faucet](https://faucet.ghostnet.teztnets.xyz/)
2. Wait 1-2 minutes for confirmation
3. Verify: `npm run account:balance`

### Container Errors

**Symptoms:** Containers won't start or crash

**Solutions:**
```bash
# Check Docker is running
docker info

# Check container logs
docker logs tezos-node
docker logs tezos-baker

# Restart containers
npm run node:stop
npm run node:start
```

### DAL Not Working

**Symptoms:** Baker shows "without DAL" or no DAL attestations

**This is NORMAL if:**
- You don't have DAL shard assignments (random, like baking rights)
- Baker logs show: "has no assigned DAL shards at level"

**This is a PROBLEM if:**
- DAL container not running
- Baker can't connect to DAL node

**Solutions:**
```bash
# Check DAL status
npm run dal:verify

# Check DAL container
docker ps | grep dal

# Restart DAL
npm run dal:restart

# Reconfigure baker
npm run baker:enable-dal

# Check DAL logs for errors
npm run dal:logs
```

**Common DAL issues:**
1. **Container name conflict** - Run `npm run dal:stop` then `npm run dal:start`
2. **Baker not reconfigured** - Run `npm run baker:enable-dal` to update baker
3. **DAL node crashed** - Check logs with `npm run dal:logs` for errors

### Starting Fresh (Complete Reset)

**If everything is broken, start over:**

```bash
# 1. Stop all containers
docker rm -f $(docker ps -aq --filter name=tezos)

# 2. Remove all data (WARNING: loses wallet if not backed up!)
rm -rf data/

# 3. Remove downloaded snapshots
rm -rf backups/*

# 4. Start from Quick Start step 1
npm run setup
```

**⚠️ WARNING:** This deletes your wallet! Only do this on testnet or if you have backup.

## Configuration

All settings are in `.env`:

**Core settings:**
- `TEZOS_NETWORK=ghostnet`
- `OCTEZ_VERSION=octez-v23.1`
- `PROTOCOL=PtSeouLo`
- `HISTORY_MODE=rolling`
- `BAKER_ALIAS=alice`
- `RPC_PORT=8732`
- `P2P_PORT=9732`

**DAL settings (optional):**
- `DAL_DATA_DIR=./dal-data`
- `DAL_RPC_PORT=10732`
- `DAL_P2P_PORT=11732`

## Resources

**Official Docs:**
[Octez](https://octez.tezos.com/docs/) • [OpenTezos](https://opentezos.com/node-baking/) • [Tezos GitLab](https://tezos.gitlab.io/)

**Ghostnet Tools:**
[Faucet](https://faucet.ghostnet.teztnets.xyz/) • [Explorer](https://ghostnet.tzkt.io/)

**Detailed Guides:**
[Staking Guide](docs/STAKING-GUIDE.md) • [Monitoring Guide](docs/MONITORING-GUIDE.md) • [Production Docs](docs/archive/)

## 🎓 Study Mode (Current Setup)

**Ghostnet Testnet:**
- **Stake required:** 6,000+ ꜩ (testnet tokens, zero value)
- **Get tokens:** [Ghostnet Faucet](https://faucet.ghostnet.teztnets.xyz/)
- **Infrastructure:** Any computer (laptop OK, no 24/7 required)
- **Security:** Basic (no Ledger needed for testnet)
- **Cost:** $0 (completely free for learning)

**Purpose:** Learn Tezos baking mechanics without financial risk.

**For production/mainnet:** See [docs/archive/PRODUCTION-GUIDE.md](docs/archive/) (when available)

## Archived Documentation

Production guides moved to `docs/archive/`:
- Security guides - RPC hardening, firewall config
- Production readiness - Deployment checklist
- Monitoring stack - Full Grafana/Prometheus setup

**Note:** These are for future production deployment. Not needed for Ghostnet study mode.

## Next Steps

After your baker is running:

1. **Monitor operations:** `npm run node:logs` regularly
2. **Check staking:** `npm run stake:status` weekly
3. **Track on explorer:** Search your address on [ghostnet.tzkt.io](https://ghostnet.tzkt.io/)
4. **Wait for rights:** First baking rights appear after ~14-21 days

---

**Study Mode Version:** 1.0.0
**Last Updated:** 2026-01-10
**Optimized for:** Ghostnet testnet learning
**Production docs:** See `docs/archive/`
