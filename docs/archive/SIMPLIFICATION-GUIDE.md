# Tezos Baker Simplification Guide

**For:** AI assistants or developers implementing simplification
**Based on:** DEEP_SIMPLIFICATION_RESEARCH.md + CLAUDE-CODE-COMPLEXITY-ANALYSIS.md
**Target:** Reduce complexity from 10.5x to 3x official minimal setup
**Time:** 2-4 hours implementation
**Risk:** Low (testnet, everything archived, reversible)

---

## Overview

### Current State
- 51 npm scripts
- 12 shell scripts
- 26 documentation files
- 7 Docker containers
- Complexity: 10.5x official minimal setup

### Target State
- 15 npm scripts (70% reduction)
- 5 shell scripts (58% reduction)
- 5 documentation files (81% reduction)
- 2 Docker containers (71% reduction)
- Complexity: 3x official minimal setup

---

## Prerequisites

Before starting, verify:

```bash
# 1. You are in the repo root
pwd
# Expected: /Users/admin/tezos-baker

# 2. Git is initialized
git status

# 3. Current setup is working
docker ps | grep tezos
# Expected: tezos-node and tezos-baker running
```

---

## Phase 1: Backup (5 minutes)

### Step 1.1: Create Git Backup

```bash
# Stage all changes
git add .

# Commit current state
git commit -m "Backup before simplification - $(date +%Y-%m-%d)"

# Create backup branch
git branch backup-before-simplification

# Verify
git branch | grep backup
```

**Success:** ✅ Backup branch exists

---

## Phase 2: Stop and Archive Monitoring Stack (10 minutes)

### Step 2.1: Stop Monitoring Containers

```bash
cd monitoring
docker-compose down
cd ..
```

### Step 2.2: Verify Monitoring Stopped

```bash
docker ps | grep -E "prometheus|grafana|loki|promtail|exporter"
# Expected: No output (all stopped)
```

### Step 2.3: Archive Monitoring Configs (Optional)

```bash
# Keep monitoring configs for future use
mkdir -p archive/monitoring
cp -r monitoring/ archive/monitoring/
```

**Success:** ✅ 5 containers stopped, saves 1GB RAM

---

## Phase 3: Archive Documentation (10 minutes)

### Step 3.1: Create Archive Directory

```bash
mkdir -p docs/archive
```

### Step 3.2: Move Non-Essential Docs

```bash
# Security docs (production only)
mv docs/SECURITY.md docs/archive/ 2>/dev/null || true
mv docs/SECURITY_QUICK_REFERENCE.md docs/archive/ 2>/dev/null || true

# Production docs
mv docs/PRODUCTION_READINESS.md docs/archive/ 2>/dev/null || true
mv docs/BLOCK_ANATOMY.md docs/archive/ 2>/dev/null || true

# Monitoring docs (stack removed)
mv docs/GRAFANA_SETUP.md docs/archive/ 2>/dev/null || true
mv docs/GRAFANAZOS_*.md docs/archive/ 2>/dev/null || true
mv docs/LOKI_*.md docs/archive/ 2>/dev/null || true

# Migration docs
mv docs/MIGRATION*.md docs/archive/ 2>/dev/null || true

# Miscellaneous
mv docs/GHOSTNET_URLS.md docs/archive/ 2>/dev/null || true
```

### Step 3.3: Keep Essential Docs

**Keep these files:**
1. `README.md` - Main guide
2. `docs/STAKING-QUICK-START.md` - Critical for staking
3. `docs/STAKING-GUIDE.md` - Detailed education
4. `docs/CLAUDE-CODE-COMPLEXITY-ANALYSIS.md` - Reference
5. `docs/SIMPLIFICATION-GUIDE.md` - This file

### Step 3.4: Verify

```bash
ls -1 docs/*.md | wc -l
# Expected: 4-6 files

ls docs/archive/ | wc -l
# Expected: 15+ files
```

**Success:** ✅ Documentation reduced from 26 to 5 files

---

## Phase 4: Remove Redundant Shell Scripts (5 minutes)

### Step 4.1: Identify Scripts to Remove

**Remove these 7 scripts:**

1. `after-reboot.sh` - Replaced by: `npm run node:start && npm run baker:start`
2. `baker-status.sh` - Replaced by: `docker logs tezos-baker`
3. `configure-rpc-acl.sh` - Production only
4. `inspect-block.sh` - Advanced debugging
5. `monitor.sh` - Replaced by: `docker logs`
6. `verify-production.sh` - Production only
7. `setup-grafazos.sh` - Monitoring stack removed

### Step 4.2: Remove Scripts

```bash
cd scripts
rm after-reboot.sh 2>/dev/null || true
rm baker-status.sh 2>/dev/null || true
rm configure-rpc-acl.sh 2>/dev/null || true
rm inspect-block.sh 2>/dev/null || true
rm monitor.sh 2>/dev/null || true
rm verify-production.sh 2>/dev/null || true
rm setup-grafazos.sh 2>/dev/null || true
cd ..
```

### Step 4.3: Keep Essential Scripts

**Keep these 5 scripts:**
1. `help.sh` - Command reference
2. `stake-status.sh` - Staking info
3. `stake-funds.sh` - Staking operations
4. `node-stop.sh` - Stop node
5. `baker-stop.sh` - Stop baker

### Step 4.4: Verify

```bash
ls -1 scripts/*.sh | wc -l
# Expected: 5 scripts
```

**Success:** ✅ Scripts reduced from 12 to 5

---

## Phase 5: Simplify package.json (20 minutes)

### Step 5.1: Understand the 15 Essential Commands

**Setup (3):**
- `setup` - Initialize node
- `snapshot:download` - Download snapshot
- `snapshot:import` - Import snapshot

**Node (3):**
- `node:start` - Start node
- `node:stop` - Stop node
- `node:logs` - View logs

**Account (3):**
- `account:create` - Create account
- `account:show` - Show address
- `account:balance` - Check balance

**Staking (2):**
- `stake:status` - Check staking
- `stake:all` - Stake funds

**Baking (3):**
- `delegate:register` - Register as delegate
- `baker:start` - Start baker
- `baker:logs` - View logs

**Help (1):**
- `help` - Show commands

### Step 5.2: Scripts to Remove (36 total)

**From Setup:**
- `node:init` - Covered by `setup`
- `node:identity` - Covered by `setup`
- `node:version` - Covered by `setup`
- `setup:snapshot` - Redundant

**From Node:**
- `node:restart` - Use `stop` + `start`
- `node:status` - Covered by `logs`
- `node:bootstrap` - Auto-handled
- `node:head` - Advanced
- `node:connections` - Advanced
- `node:peers` - Advanced
- `node:chain-id` - Advanced
- `snapshot:check` - Not needed

**From Account:**
- `account:balance:full` - Redundant

**From Staking:**
- `stake:balance` - Covered by `stake:status`
- `stake:half` - Not needed for testnet
- `stake:minimum` - Not needed for testnet
- `stake:custom` - Use `stake:all`
- `unstake:all` - Not needed for study
- `unstake:finalize` - Not needed for study

**From Baking:**
- `delegate:status` - Covered by `stake:status`
- `baker:stop` - Rarely needed
- `baker:status` - Covered by `logs`
- `baker:rights` - Wait for attestations

**From Monitoring:**
- `monitor` - Stack removed
- `verify` - Production only
- `monitoring:start` - Stack removed
- `monitoring:stop` - Stack removed
- `monitoring:logs` - Stack removed
- `grafazos:setup` - Stack removed
- `block:inspect` - Advanced
- `security:configure-acl` - Production only

**From Utilities:**
- `start` - Redundant with `node:start`
- `clean` - Use Docker commands
- `clean:data` - Dangerous
- `ps` - Use `docker ps`

### Step 5.3: Create Simplified package.json

Replace the entire `package.json` with this simplified version:

```json
{
  "name": "tezos-baker",
  "version": "1.0.0",
  "description": "Tezos baker setup for Ghostnet testnet - Simplified for study mode",
  "scripts": {
    "env": "test -f .env && echo '.env file found' || (echo 'Error: .env file not found. Copy .env.example to .env first.' && exit 1)",
    "setup": "npm run node:init && npm run node:identity && npm run node:version && echo 'Setup complete! Run: npm run node:start'",
    "node:init": "npm run env && . ./.env && mkdir -p ${DATA_DIR:-data} && docker run --rm --entrypoint octez-node -v \"$PWD/${DATA_DIR:-data}:/var/run/tezos/node\" tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} config init --network ${TEZOS_NETWORK:-ghostnet} --history-mode ${HISTORY_MODE:-rolling} --rpc-addr 0.0.0.0:${RPC_PORT:-8732} --net-addr 0.0.0.0:${P2P_PORT:-9732} --data-dir /var/run/tezos/node",
    "node:identity": "npm run env && . ./.env && docker run --rm --entrypoint octez-node -v \"$PWD/${DATA_DIR:-data}:/var/run/tezos/node\" tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} identity generate --data-dir /var/run/tezos/node",
    "node:version": "npm run env && . ./.env && docker run --rm --entrypoint sh -v \"$PWD/${DATA_DIR:-data}:/var/run/tezos/node\" tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} -c 'echo \"{\\\"version\\\": \\\"3.2\\\"}\" > /var/run/tezos/node/version.json'",
    "snapshot:download": "npm run env && . ./.env && mkdir -p ${BACKUP_DIR:-backups} && cd ${BACKUP_DIR:-backups} && wget -O ${TEZOS_NETWORK:-ghostnet}-rolling.snapshot https://snapshots.tzinit.org/${TEZOS_NETWORK:-ghostnet}/rolling",
    "snapshot:import": "npm run env && . ./.env && docker run --rm --entrypoint octez-node -v \"$PWD/${DATA_DIR:-data}:/var/run/tezos/node\" -v \"$PWD/${BACKUP_DIR:-backups}:/backups:ro\" tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} snapshot import /backups/${TEZOS_NETWORK:-ghostnet}-rolling.snapshot --data-dir /var/run/tezos/node",
    "node:start": "npm run env && . ./.env && docker run -d --name ${CONTAINER_PREFIX:-tezos}-node --entrypoint octez-node -v \"$PWD/${DATA_DIR:-data}:/var/run/tezos/node\" -p ${RPC_PORT:-8732}:${RPC_PORT:-8732} -p ${P2P_PORT:-9732}:${P2P_PORT:-9732} -p ${METRICS_PORT:-9095}:${METRICS_PORT:-9095} tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} run --network ${TEZOS_NETWORK:-ghostnet} --data-dir /var/run/tezos/node --metrics-addr 0.0.0.0:${METRICS_PORT:-9095}",
    "node:stop": "./scripts/node-stop.sh",
    "node:logs": ". ./.env 2>/dev/null || true && docker logs -f ${CONTAINER_PREFIX:-tezos}-node",
    "account:create": "npm run env && . ./.env && docker exec ${CONTAINER_PREFIX:-tezos}-node octez-client -d /var/run/tezos/node/.tezos-client --endpoint http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732} gen keys ${BAKER_ALIAS:-alice}",
    "account:show": "npm run env && . ./.env && docker exec ${CONTAINER_PREFIX:-tezos}-node octez-client -d /var/run/tezos/node/.tezos-client --endpoint http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732} show address ${BAKER_ALIAS:-alice}",
    "account:balance": "npm run env && . ./.env && docker exec ${CONTAINER_PREFIX:-tezos}-node octez-client -d /var/run/tezos/node/.tezos-client --endpoint http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732} get balance for ${BAKER_ALIAS:-alice}",
    "stake:status": "./scripts/stake-status.sh",
    "stake:all": "./scripts/stake-funds.sh all",
    "delegate:register": "npm run env && . ./.env && docker exec ${CONTAINER_PREFIX:-tezos}-node octez-client -d /var/run/tezos/node/.tezos-client --endpoint http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732} register key ${BAKER_ALIAS:-alice} as delegate",
    "baker:start": "npm run env && . ./.env && docker run -d --name ${CONTAINER_PREFIX:-tezos}-baker --network container:${CONTAINER_PREFIX:-tezos}-node -v \"$PWD/${DATA_DIR:-data}:/var/run/tezos/node\" -v \"$PWD/${DATA_DIR:-data}/.tezos-client:/home/tezos/.tezos-client\" --entrypoint octez-baker-${PROTOCOL:-PtSeouLo} tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} run with local node /var/run/tezos/node --without-dal --liquidity-baking-toggle-vote pass ${BAKER_ALIAS:-alice}",
    "baker:logs": ". ./.env 2>/dev/null || true && docker logs -f ${CONTAINER_PREFIX:-tezos}-baker",
    "help": "./scripts/help.sh"
  },
  "keywords": [
    "tezos",
    "baker",
    "blockchain",
    "ghostnet",
    "octez",
    "simplified"
  ],
  "author": "",
  "license": "MIT"
}
```

### Step 5.4: Verify

```bash
cat package.json | jq '.scripts | keys | length'
# Expected: 18-19 (15 user commands + 3 internal helpers)
```

**Success:** ✅ package.json reduced from 51 to 15 essential commands

---

## Phase 6: Update Help Script (10 minutes)

### Step 6.1: Create Simplified Help

```bash
cat > scripts/help.sh << 'EOF'
#!/usr/bin/env bash

cat << 'HELP'

Tezos Baker - Simplified Study Mode
====================================

Setup & Initialization:
  npm run setup                Initialize node configuration and identity
  npm run snapshot:download    Download latest Ghostnet rolling snapshot
  npm run snapshot:import      Import downloaded snapshot (stop node first)

Node Management:
  npm run node:start           Start the Tezos node
  npm run node:stop            Stop the node
  npm run node:logs            View live node logs

Account Management:
  npm run account:create       Create new account (alice)
  npm run account:show         Show account address
  npm run account:balance      Check account balance

Staking Operations:
  npm run stake:status         Show comprehensive staking status
  npm run stake:all            Stake all available funds

Delegation & Baking:
  npm run delegate:register    Register account as delegate
  npm run baker:start          Start the baker
  npm run baker:logs           View live baker logs

Utilities:
  npm run help                 Show this help message

Quick Start (Study Mode):
  1. npm run setup
  2. npm run snapshot:download
  3. npm run snapshot:import
  4. npm run node:start
  5. npm run account:create
  6. Get testnet XTZ from https://faucet.ghostnet.teztnets.xyz/
  7. npm run delegate:register
  8. npm run stake:all          ⚠️  CRITICAL: Must stake to receive baking rights!
  9. npm run baker:start
  10. Wait 14-21 days for baking rights

Direct Docker Commands (Advanced):
  docker ps                            # Show running containers
  docker logs -f tezos-node           # View node logs
  docker logs -f tezos-baker          # View baker logs
  docker rm -f tezos-node tezos-baker # Stop and remove containers

Resources:
  Blockchain Explorer: https://ghostnet.tzkt.io/
  Testnet Faucet: https://faucet.ghostnet.teztnets.xyz/
  Documentation: README.md, docs/STAKING-QUICK-START.md

Note: This is simplified study mode (15 essential commands).
      Advanced features archived for future production use.

HELP
EOF

chmod +x scripts/help.sh
```

### Step 6.2: Test Help

```bash
npm run help
# Expected: Shows simplified help with 15 commands
```

**Success:** ✅ Help updated for simplified command set

---

## Phase 7: Verify Everything Works (10 minutes)

### Step 7.1: Check Containers Running

```bash
docker ps | grep tezos
# Expected: tezos-node and tezos-baker running
```

### Step 7.2: Test Essential Commands

```bash
# Test staking status
npm run stake:status
# Expected: Shows current staking status

# Test balance check
npm run account:balance
# Expected: Shows account balance

# Test logs
docker logs tezos-node --tail 10
docker logs tezos-baker --tail 10
# Expected: Recent log entries

# Test help
npm run help
# Expected: Shows 15 commands
```

### Step 7.3: Verification Checklist

- [ ] Git backup branch exists
- [ ] Monitoring containers stopped (5 containers)
- [ ] Documentation archived (15+ files in docs/archive/)
- [ ] Shell scripts reduced (5 scripts remain)
- [ ] npm scripts reduced (15 essential commands)
- [ ] Help shows simplified command set
- [ ] Node container running
- [ ] Baker container running
- [ ] Stake status works
- [ ] Account balance works
- [ ] Logs accessible

**Success:** ✅ All verification checks passed

---

## Phase 8: Commit Simplified Setup (5 minutes)

### Step 8.1: Stage All Changes

```bash
git add .
```

### Step 8.2: Commit with Detailed Message

```bash
git commit -m "Simplify setup: 51→15 commands, 12→5 scripts, 26→5 docs, 7→2 containers

Changes:
- Removed monitoring stack (5 containers, saves 1GB RAM)
- Archived 21 documentation files (kept 5 essential)
- Removed 7 shell scripts (kept 5 essential)
- Simplified package.json from 51 to 15 npm scripts
- Updated help.sh for simplified command set

Results:
- Complexity reduced from 10.5x to 3x official minimal setup
- RAM usage: 3GB → 2GB (33% reduction)
- Focus on core learning for testnet study mode

All changes reversible via: git checkout backup-before-simplification"
```

### Step 8.3: Verify Commit

```bash
git log -1 --oneline
# Expected: Shows commit message

git branch
# Expected: Shows current branch and backup branch
```

**Success:** ✅ Simplified setup saved to git

---

## Phase 9: Update Documentation (15 minutes)

### Step 9.1: Update README Quick Start

Add this section to README.md:

```markdown
## Quick Start (Simplified Study Mode)

This setup has been simplified for testnet learning:

**Setup (once):**
```bash
npm run setup                 # Initialize node
npm run snapshot:download     # Download snapshot (~1.6GB)
npm run snapshot:import       # Import snapshot
npm run node:start            # Start node
npm run account:create        # Create account
# Get testnet XTZ from https://faucet.ghostnet.teztnets.xyz/
npm run delegate:register     # Register as delegate
npm run stake:all             # Stake funds (REQUIRED!)
npm run baker:start           # Start baker
```

**Daily monitoring:**
```bash
npm run node:logs            # Check node
npm run baker:logs           # Check baker
npm run stake:status         # Check staking
```

**Available commands:**
```bash
npm run help                 # Show all 15 commands
```

**Timeline:**
- Day 0: Stake funds ✅
- Days 1-21: Wait for baking rights (check weekly)
- Day 21+: Start seeing attestations

**Resources:**
- Help: `npm run help`
- Staking guide: `docs/STAKING-QUICK-START.md`
- Blockchain explorer: https://ghostnet.tzkt.io/
```

### Step 9.2: Create Simplification Changelog

Create `docs/CHANGELOG-SIMPLIFICATION.md`:

```markdown
# Simplification Changelog

## Version 2.0 - Simplified Study Mode

**Date:** [Current Date]

### Changes

**Removed:**
- 36 npm scripts (51 → 15)
- 7 shell scripts (12 → 5)
- 21 documentation files (26 → 5)
- 5 monitoring containers (7 → 2)

**Archived:**
- All production-only scripts
- Advanced debugging tools
- Monitoring stack configurations
- Detailed security guides

**Kept:**
- 15 essential commands for testnet
- 5 helper scripts
- Core documentation
- Staking guides (critical)

### Command Mapping

| Old Command | New Command | Notes |
|-------------|-------------|-------|
| `npm run node:init` | `npm run setup` | Consolidated |
| `npm run node:identity` | `npm run setup` | Consolidated |
| `npm run node:version` | `npm run setup` | Consolidated |
| `npm run monitor` | `docker logs tezos-node` | Use Docker |
| `npm run stake:custom` | `npm run stake:all` | Simplified |
| `npm run baker:status` | `npm run baker:logs` | Use logs |
| `npm run clean` | `docker rm -f tezos-node` | Use Docker |

### Restore Complex Setup

To restore the previous complex setup:

```bash
git checkout backup-before-simplification
```

### Benefits

- 70% reduction in complexity
- 33% reduction in RAM usage
- Faster learning curve
- Clearer focus on core concepts
- Easier to understand and maintain
```

**Success:** ✅ Documentation updated

---

## Summary

### What Changed

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| npm scripts | 51 | 15 | 70% |
| Shell scripts | 12 | 5 | 58% |
| Documentation | 26 | 5 | 81% |
| Docker containers | 7 | 2 | 71% |
| RAM usage | ~3GB | ~2GB | 33% |
| Complexity | 10.5x | 3x | 71% |

### What You Kept (15 Essential Commands)

**Setup (3):**
- `npm run setup`
- `npm run snapshot:download`
- `npm run snapshot:import`

**Node (3):**
- `npm run node:start`
- `npm run node:stop`
- `npm run node:logs`

**Account (3):**
- `npm run account:create`
- `npm run account:show`
- `npm run account:balance`

**Staking (2):**
- `npm run stake:status`
- `npm run stake:all`

**Baking (3):**
- `npm run delegate:register`
- `npm run baker:start`
- `npm run baker:logs`

**Help (1):**
- `npm run help`

### Daily Workflow After Simplification

```bash
# Check baker health
npm run node:logs
npm run baker:logs

# Check staking
npm run stake:status
```

That's it! Everything else was complexity for production.

---

## Troubleshooting

### Problem: npm run help shows old commands

**Solution:**
```bash
npm cache clean --force
npm run help
```

### Problem: Container not found

**Solution:**
```bash
# Check what's running
docker ps

# Restart if needed
npm run node:start
npm run baker:start
```

### Problem: Want to restore complex setup

**Solution:**
```bash
git checkout backup-before-simplification
```

---

## Verification Checklist

After completing all phases:

- [ ] Git backup branch exists
- [ ] Monitoring stopped (0 prometheus/grafana containers)
- [ ] Documentation archived (docs/archive/ has 15+ files)
- [ ] Scripts reduced (5 .sh files in scripts/)
- [ ] package.json simplified (15 commands)
- [ ] Help shows simplified commands
- [ ] Node running (`docker ps | grep tezos-node`)
- [ ] Baker running (`docker ps | grep tezos-baker`)
- [ ] Commands work (`npm run stake:status`)
- [ ] Changes committed (`git log -1`)

**All checked?** ✅ Simplification complete!

---

## What You Achieved

**Before:**
- Complex production-ready setup
- Overwhelming for testnet learning
- High maintenance burden

**After:**
- Clean testnet study mode
- 15 essential commands
- Focus on core concepts
- Easy to understand

**Learning Benefits:**
1. Clearer understanding of core functionality
2. Less confusion about what's essential
3. Better resource usage (saves 1GB RAM)
4. Easier to maintain and modify
5. Faster learning curve

---

## Next Steps

1. **Learn the 15 commands** - Run `npm run help`
2. **Follow quick start** - README.md guide
3. **Read staking guide** - docs/STAKING-QUICK-START.md
4. **Monitor your baker** - Wait 2-3 weeks for attestations
5. **Understand PoS** - Watch how Tezos consensus works

**Remember:** You can always restore the complex setup from the backup branch if needed for production later.

---

## Reference

- **Current setup:** Simplified (15 commands)
- **Backup:** `backup-before-simplification` branch
- **Analysis:** `docs/CLAUDE-CODE-COMPLEXITY-ANALYSIS.md`
- **Deep research:** `docs/DEEP_SIMPLIFICATION_RESEARCH.md`
- **Staking:** `docs/STAKING-QUICK-START.md`

---

**Status:** ✅ Ready for testnet study mode
**Complexity:** 3x official minimal (down from 10.5x)
**Focus:** Learning Tezos Proof-of-Stake on Ghostnet
