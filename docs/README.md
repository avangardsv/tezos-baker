# Tezos Baker - Study Mode Documentation

Simplified documentation for learning Tezos baking on Ghostnet testnet.

## Quick Start (5 Minutes)

### Prerequisites
- Docker installed
- .env file configured (copy from .env.example)

### Initial Setup
```bash
npm run setup                   # Initialize node + identity
npm run snapshot:download       # Download Ghostnet snapshot (recommended)
npm run snapshot:import         # Import snapshot for fast sync
npm run node:start              # Start Tezos node
```

### Create Baker Account
```bash
npm run account:create          # Generate keys
npm run account:show            # Get your address (fund it via faucet)
npm run account:balance         # Verify funds received
```

### Activate Baker
```bash
npm run delegate:register       # Register as delegate
npm run stake:all               # Stake funds (CRITICAL!)
npm run baker:start             # Start baker daemon
```

**Important:** Baking rights appear 5-7 cycles (~14-21 days) after staking.

---

## 🔥 Critical: Staking Required

**If you have 0 attestations:** You must stake funds, not just have balance.

### Quick Fix
**File:** `STAKING-QUICK-START.md` (5 minute read)

**Quick commands:**
```bash
npm run stake:status            # Check staking status
npm run stake:all               # Stake all funds (reserve 0.5 for fees)
```

### Complete Staking Guide
**File:** `STAKING-GUIDE.md` (30 minute educational guide)

Learn staking concepts, lifecycle, all commands, and troubleshooting.

---

## Essential Commands

### Node Management
```bash
npm run node:start              # Start node
npm run node:stop               # Stop node
npm run node:logs               # View node logs
```

### Account Operations
```bash
npm run account:create          # Generate baker keys
npm run account:show            # Display address and keys
npm run account:balance         # Check balance
```

### Staking Operations
```bash
npm run stake:status            # Check staking status
npm run stake:all               # Stake all funds
```

### Delegation & Baking
```bash
npm run delegate:register       # Register as delegate
npm run baker:start             # Start baker
npm run baker:logs              # View baker logs
```

### Utilities
```bash
npm run help                    # Show all commands
```

---

## Monitoring & Troubleshooting

### Check Status
```bash
docker ps                       # Verify containers running
npm run node:logs               # Check node sync status
npm run baker:logs              # Check baker activity
npm run stake:status            # Verify staking active
```

### Common Issues

**Node not syncing:**
- Wait for bootstrap (can take hours without snapshot)
- Use snapshot import for faster sync

**Baker not producing blocks:**
- Check staking status (must have staked balance)
- Wait 5-7 cycles after staking for rights
- Verify delegate registration

**Container errors:**
- Check .env configuration
- Verify ports not in use (8732, 9732)
- Check Docker resources available

---

## 📊 Important Metrics & Health Checks

### Quick Health Check

```bash
# Check P2P connections
curl -s http://localhost:9095/metrics | grep "octez_p2p_connections"

# Check sync status
curl -s http://localhost:9095/metrics | grep "octez_validator_chain_is_bootstrapped"

# Check current block level
curl -s http://localhost:9095/metrics | grep "octez_validator_chain_head_level"
```

### Key Metrics to Monitor

#### 1. P2P Connections (Network Health)

**Check command:**
```bash
curl -s http://localhost:9095/metrics | grep "octez_p2p_connections" | grep -v "^#"
```

**Healthy values for Ghostnet:**
- **Active connections:** 10-30 (you have ~24) ✓
- **Outgoing connections:** 10-30 ✓
- **Incoming connections:** 0+ (0 is OK for testnet behind firewall)
- **Private connections:** Usually 0

**What they mean:**
- **Outgoing:** Your node connects to other peers (critical)
- **Incoming:** Other peers connect to you (requires port forwarding)
- **Active:** Total connected peers

**Note:** 0 incoming connections is normal for home networks without port forwarding. Your node stays synced via outgoing connections.

#### 2. Node Sync Status

**Check command:**
```bash
curl -s http://localhost:9095/metrics | grep "octez_validator_chain_is_bootstrapped"
```

**Healthy value:**
- `octez_validator_chain_is_bootstrapped 1.000000` ✓ (fully synced)
- `octez_validator_chain_is_bootstrapped 0.000000` ✗ (still syncing)

#### 3. Block Level (Chain Progress)

**Check command:**
```bash
curl -s http://localhost:9095/metrics | grep "octez_validator_chain_head_level"
```

Compare your level with explorer: https://ghostnet.tzkt.io/

**Lag check:**
- Behind by 0-10 blocks: ✓ Excellent
- Behind by 10-100 blocks: ⚠️ Catching up
- Behind by >100 blocks: ✗ Sync issue

#### 4. P2P Bandwidth

**Check command:**
```bash
curl -s http://localhost:9095/metrics | grep "octez_p2p_io_scheduler_current"
```

**Healthy values:**
- **Inflow:** 10-100 KB/s (receiving blockchain data)
- **Outflow:** 1-20 KB/s (sending data to peers)

#### 5. Staking Status (Critical for Baking!)

**Check command:**
```bash
npm run stake:status
```

**Healthy status:**
- **Liquid balance:** Some ꜩ for fees (keep 1-10 ꜩ)
- **Staked balance:** >6000 ꜩ (6000 minimum, more = better)
- **Delegation:** Self-delegated ✓
- **Baker status:** Registered as delegate ✓

**Red flags:**
- Staked balance = 0 → Won't receive baking rights!
- Not delegated → Won't participate in consensus
- Liquid balance = 0 → Can't pay transaction fees

---

## 📈 Grafana Monitoring (Optional)

Grafana provides visual dashboards for all metrics.

### Start Grafana

```bash
cd monitoring
docker-compose up -d
```

**Access:** http://localhost:3000
**Login:** admin / tezos_monitoring_2026

### Available Dashboards

| Dashboard | Best For | URL |
|-----------|----------|-----|
| **Octez compact** | Quick overview (start here) | http://localhost:3000/d/2260c35a-c3e1-40c3-b143-8c0ec9d82216/octez-compact |
| **Octez basic** | Detailed metrics | http://localhost:3000/d/1d8a18a6-7674-4bd8-9692-9e0e64af5118/octez-basic |
| **Octez full** | Complete monitoring + hardware | http://localhost:3000/d/ad9kq8j/octez-full |
| **Octez with logs** | With log correlation | http://localhost:3000/d/ad768nt/octez-with-logs |

**Important:** Select `host.docker.internal:9095` from the **node_instance** dropdown to see data!

### Key Grafana Panels

**In Octez compact dashboard:**
- **P2P total connections** - Should show 20-30
- **Connections** (incoming) - Usually 0 for home setups
- **Bootstrap status** - Must be "YES"
- **Head level** - Should match network
- **Validation errors** - Should be 0

### Stop Grafana (Save Resources)

```bash
cd monitoring
docker-compose down
```

**Grafana uses ~1GB RAM** - optional for Ghostnet learning. Use `docker logs` for simple monitoring.

---

## 🚨 Health Check Summary

Run this quick health check anytime:

```bash
echo "=== BAKER HEALTH CHECK ===" && \
echo "" && \
echo "📊 P2P Connections:" && \
curl -s http://localhost:9095/metrics | grep "octez_p2p_connections_active" | awk '{print "   Active: " $2}' && \
echo "" && \
echo "✅ Sync Status:" && \
curl -s http://localhost:9095/metrics | grep "octez_validator_chain_is_bootstrapped" | awk '{if($2==1) print "   Bootstrapped: YES ✓"; else print "   Bootstrapped: NO ✗"}' && \
echo "" && \
echo "📈 Block Level:" && \
curl -s http://localhost:9095/metrics | grep "octez_validator_chain_head_level" | awk '{print "   Level: " $2}' && \
echo "" && \
echo "💰 Staking:" && \
npm run stake:status 2>/dev/null | grep -E "Staked|Liquid|Total" && \
echo "" && \
echo "🐳 Containers:" && \
docker ps --format "   {{.Names}}: {{.Status}}" | grep tezos
```

**Expected output:**
- P2P connections: 10-30 ✓
- Bootstrapped: YES ✓
- Block level: Close to network head ✓
- Staked balance: >6000 ꜩ ✓
- Containers: tezos-node and tezos-baker running ✓

---

## Additional Resources

### Official Documentation
- [Tezos Docs](https://tezos.gitlab.io/)
- [Octez Documentation](https://octez.tezos.com/docs/)
- [OpenTezos Baking Guide](https://opentezos.com/node-baking/)

### Ghostnet Resources
- [Ghostnet Faucet](https://faucet.ghostnet.tezostaquito.io/)
- [Ghostnet Explorer](https://ghostnet.tzkt.io/)

### Archived Documentation
See `docs/archive/` for production guides, security documentation, and advanced setup instructions.

---

## Simplification Notes

This repo has been simplified for study mode (Ghostnet testnet):
- Reduced from 51 to 15 essential commands
- Removed monitoring stack (use `docker logs`)
- Archived production/security docs
- See `SIMPLIFICATION-GUIDE.md` for migration details
- See `CHANGELOG-SIMPLIFICATION.md` for change history

**Production setup:** Archived guides available in `docs/archive/`

---

**Last Updated:** 2026-01-06
