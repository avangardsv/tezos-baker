# Tezos Node Production Readiness Guide

This guide helps you verify your Tezos node is correctly configured and ready for production deployment.

## Quick Verification

Run the automated verification:

```bash
npm run verify
```

This checks 7 categories with 25+ individual tests.

## Verification Categories

### 1. ✅ Docker Container Health

**What it checks:**
- Container is running
- Container state is healthy
- No unexpected restarts

**How to verify manually:**
```bash
docker ps | grep tezos-node
docker inspect tezos-node --format='{{.State.Status}}'
docker inspect tezos-node --format='{{.RestartCount}}'
```

**Production requirements:**
- Container status: `running`
- Restart count: `0` (or low number)
- Uptime: Stable (no frequent restarts)

---

### 2. 🌐 Network Configuration

**What it checks:**
- RPC port (8732) exposed
- P2P port (9732) exposed  
- RPC endpoint accessible
- Peer connections (minimum: 5, healthy: ≥10)

**How to verify manually:**
```bash
# Check ports
docker port tezos-node

# Check RPC
curl -s http://127.0.0.1:8732/chains/main/chain_id

# Check peer count
npm run node:connections
```

**Production requirements:**
- RPC accessible: ✅
- P2P port open: ✅
- Peer count: **≥10 for production**, minimum 5
- Stable connections (not dropping frequently)

---

### 3. ⛓️ Blockchain Synchronization

**What it checks:**
- Block data accessible
- Chain synchronized (head timestamp recent)
- Actively processing blocks

**How to verify manually:**
```bash
# Current block
npm run node:head

# Check sync status
docker logs --tail 20 tezos-node 2>&1 | grep -E "synced|synchronizing|head is now"

# Monitor real-time
npm run node:logs
```

**Production requirements:**
- Block data: Available ✅
- Head age: **< 60 seconds** (synced)
- Status: "synced" or "head is now" in logs
- Block processing: Every ~4 seconds for Ghostnet

**Current Status:**
Your node is currently **catching up** after the restart (9+ hours behind). This is normal and expected. It will reach sync within 1-2 hours depending on network speed.

---

### 4. 📁 Data Integrity

**What it checks:**
- Config file exists and valid JSON
- Network matches .env configuration
- History mode correct
- Identity file exists and valid
- Context directory present

**How to verify manually:**
```bash
# Verify config
cat data/config.json | jq .

# Check network
cat data/config.json | jq .network

# Check history mode
cat data/config.json | jq .shell.history_mode

# Verify identity
cat data/identity.json | jq .peer_id

# Check context size
du -sh data/context
```

**Production requirements:**
- Config: Valid JSON ✅
- Network: Matches deployment target (ghostnet/mainnet)
- History mode: `rolling` (space-efficient) or `full` (complete history)
- Identity: Present with valid peer_id
- Context: Growing over time (indicates active sync)

---

### 5. 🔧 Protocol & Version

**What it checks:**
- Protocol hash present
- Octez version matches deployment

**How to verify manually:**
```bash
# Check protocol
curl -s http://127.0.0.1:8732/chains/main/blocks/head/header | jq .protocol

# Check Octez version
docker exec tezos-node octez-node --version
```

**Production requirements:**
- Protocol: Current network protocol (PtSeouLouX for Ghostnet)
- Version: **octez-v23.1** (latest stable as of Dec 2024)

---

### 6. 💾 Resource Usage

**What it checks:**
- Memory usage reasonable
- CPU usage tracked
- Disk usage monitored

**How to verify manually:**
```bash
# Real-time stats
docker stats tezos-node

# Disk usage
du -sh data/
df -h
```

**Production requirements:**
- **Memory**: 2-4 GB typical, 8 GB recommended for mainnet
- **CPU**: High during sync (~100%), low when synced (~5-15%)
- **Disk**: 
  - Rolling: 20-50 GB
  - Full: 100-200 GB
  - Archive: 500+ GB

**Current**: 874 MB RAM, 98% CPU (syncing), 3.2 GB disk - all normal for catching up.

---

### 7. 🔒 Security Configuration

**What it checks:**
- RPC ACL configured
- RPC exposure (0.0.0.0 vs 127.0.0.1)

**How to verify manually:**
```bash
# Check ACL
cat data/config.json | jq .rpc.acl

# Check listen address
cat data/config.json | jq .rpc
```

**Production requirements:**

#### For Testnet (Current):
- ✅ ACL configured (allows localhost)
- ⚠️  Listening on 0.0.0.0 (acceptable with firewall)

#### For Mainnet Production:
- ✅ **Strong ACL rules** (whitelist specific IPs)
- ✅ **Firewall configured** (UFW/iptables)
- ✅ **HTTPS/TLS** for external RPC access
- ✅ **Separate signer** for baker keys (hardware wallet recommended)
- ✅ **Monitoring & alerts** configured
- ✅ **Backup strategy** in place

---

## Production Deployment Checklist

### Before Going to Production:

- [ ] **1. Environment Configuration**
  - [ ] `.env` configured for mainnet (if deploying to mainnet)
  - [ ] OCTEZ_VERSION pinned to stable release
  - [ ] TEZOS_NETWORK set correctly

- [ ] **2. Security Hardening**
  - [ ] Firewall configured (UFW/iptables)
  - [ ] RPC ACL rules strict (whitelist only)
  - [ ] SSH key-based authentication
  - [ ] Automatic security updates enabled
  - [ ] Non-root user for Docker

- [ ] **3. Infrastructure**
  - [ ] Dedicated server (not shared hosting)
  - [ ] Minimum specs met:
    - CPU: 4+ cores
    - RAM: 8+ GB
    - Disk: 200+ GB SSD (mainnet full node)
  - [ ] Reliable network connection
  - [ ] UPS/power backup (optional but recommended)

- [ ] **4. Monitoring**
  - [ ] Node uptime monitoring
  - [ ] Block sync monitoring
  - [ ] Peer connection alerts
  - [ ] Disk space alerts
  - [ ] Log aggregation (optional: ELK, Grafana)

- [ ] **5. Backup Strategy**
  - [ ] Identity file backed up securely
  - [ ] Baker keys backed up (encrypted)
  - [ ] Regular snapshot exports
  - [ ] Disaster recovery plan documented

- [ ] **6. Testing**
  - [ ] Run `npm run verify` - all green
  - [ ] Test node restart recovery
  - [ ] Test snapshot import/export
  - [ ] Monitor for 24+ hours on testnet
  - [ ] Verify baker operations (if baking)

- [ ] **7. Documentation**
  - [ ] Deployment steps documented
  - [ ] Troubleshooting guide created
  - [ ] Contact info for emergencies
  - [ ] Runbook for common operations

---

## Verification Commands

### Run Automated Verification
```bash
npm run verify                  # Complete production readiness check
npm run verify:production       # Same + production reminder message
```

### Manual Verification Steps

```bash
# 1. Container health
docker ps | grep tezos-node
docker stats tezos-node --no-stream

# 2. Network status
npm run node:connections
npm run node:peers

# 3. Sync status
npm run node:head
npm run monitor

# 4. Logs
npm run node:logs

# 5. Resource usage
du -sh data/
df -h
```

---

## Expected Results

### ✅ Production Ready (All Green)

```
✓ Passed:  23
⚠ Warnings: 0
✗ Failed:  0

🎉 PRODUCTION READY - All checks passed!
```

### ⚠️ Needs Attention (Warnings)

```
✓ Passed:  21
⚠ Warnings: 2
✗ Failed:  0

⚠️  NEEDS ATTENTION - 2 warnings found
Review warnings before production deployment.
```

**Common warnings:**
- RPC exposed on 0.0.0.0 (configure firewall)
- Peer count between 5-10 (wait for more connections)
- Node still synchronizing (wait for sync completion)

### ❌ Not Ready (Failed Checks)

```
✓ Passed:  18
⚠ Warnings: 2
✗ Failed:  3

❌ NOT READY - 3 critical issues found
Fix critical issues before production deployment.
```

**Critical issues:**
- Container not running
- RPC not accessible
- Chain not synchronized (>5 minutes behind)
- Config file corrupt
- No peer connections

---

## Current Node Status

Run this to check your current status:

```bash
npm run monitor
```

**Your node is currently:** 
- ✅ Running and healthy
- 🔄 Catching up after restart (9+ hours behind)
- ✅ 24 peers connected
- ⏳ Will be fully synced in 1-2 hours

**Wait for full sync before production deployment!**

---

## Troubleshooting

### Node won't sync
```bash
# Check peers
npm run node:connections  # Should be ≥5

# Check logs for errors
docker logs tezos-node 2>&1 | tail -50

# Restart node
npm run node:restart
```

### High memory usage
```bash
# Check current usage
docker stats tezos-node --no-stream

# Restart to free memory
npm run node:restart
```

### RPC not accessible
```bash
# Check ACL configuration
cat data/config.json | jq .rpc.acl

# Test connectivity
curl -s http://127.0.0.1:8732/chains/main/chain_id
```

---

## Next Steps

1. **Wait for full sync**: Monitor with `npm run monitor:watch`
2. **Run verification**: `npm run verify` should show all green
3. **Review warnings**: Address any security warnings for production
4. **Test stability**: Let it run for 24 hours, check logs
5. **Deploy to production**: Follow mainnet deployment guide

---

## Support & Resources

- **Octez Documentation**: https://tezos.gitlab.io/
- **Tezos Stack Exchange**: https://tezos.stackexchange.com/
- **Discord**: https://discord.gg/tezos
- **GitHub Issues**: https://github.com/tezos/tezos/issues

---

**Last Updated**: 2024-12-19
