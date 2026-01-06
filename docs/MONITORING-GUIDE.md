# Monitoring Guide

Complete guide to monitoring your Tezos baker on Ghostnet testnet.

## Quick Metrics Check

Check if your baker is healthy:

```bash
# Check everything at once
curl -s http://localhost:9095/metrics | grep -E "p2p_connections_active|is_bootstrapped|head_level"
```

**Healthy output:**
- Connections: 10-30
- Bootstrapped: 1.000000 (means YES)
- Level: Should be close to latest block

## Key Metrics Explained

### 1. P2P Connections

**What it means:** Number of active peer connections to the Tezos network.

**Check:**
```bash
curl -s http://localhost:9095/metrics | grep p2p_connections_active
```

**Healthy values:**
- Minimum: 5 connections
- Recommended: 10-30 connections
- Too low (<5): Node may not sync properly

**What to do if low:**
- Wait a few minutes (connections build up gradually)
- Check if node is still syncing
- Verify snapshot was imported correctly

### 2. Sync Status

**What it means:** Whether your node has caught up to the latest blockchain state.

**Check:**
```bash
curl -s http://localhost:9095/metrics | grep is_bootstrapped
```

**Values:**
- `1.000000` = Fully synced (bootstrapped)
- `0.000000` = Still syncing (not bootstrapped)

**Expected timeline:**
- With snapshot: 1-2 hours to bootstrap
- Without snapshot: 1-3 days (not recommended)

### 3. Block Level

**What it means:** Current block height your node has synced to.

**Check:**
```bash
curl -s http://localhost:9095/metrics | grep head_level
```

**What to expect:**
- Should match current network height (check https://ghostnet.tzkt.io/)
- Should increase over time (new blocks being added)
- If stuck: Node may be having sync issues

### 4. Staking Status

**What it means:** Whether you have staked funds (required for baking rights).

**Check:**
```bash
npm run stake:status
```

**What to look for:**
- Staked balance > 0 (must stake to receive baking rights)
- Staking date (rights appear 14-21 days after staking)
- Total balance (includes staked + unstaked)

**Critical:** You MUST stake funds to receive baking rights. See [STAKING-GUIDE.md](STAKING-GUIDE.md) for details.

## Grafana Setup (Optional)

For advanced monitoring with visual dashboards:

**Note:** Monitoring stack has been archived. See `archive/monitoring/` for Grafana/Prometheus setup.

**Quick metrics (no Grafana needed):**
```bash
# All metrics at once
curl -s http://localhost:9095/metrics | grep -E "connections|bootstrapped|level|stake"
```

## Advanced Monitoring

### Check Node Logs

```bash
npm run node:logs
# or
docker logs -f tezos-node
```

**What to look for:**
- "synchronizing" = Node is syncing (normal)
- "bootstrapped" = Node is fully synced
- "insufficient history" = Need to import snapshot
- Connection count increasing = Good

### Check Baker Logs

```bash
npm run baker:logs
# or
docker logs -f tezos-baker
```

**What to look for:**
- "No baking rights" = Normal (wait 14-21 days after staking)
- "Baking block" = You're baking! (rare on testnet)
- "Attesting" = You're attesting blocks (more common)

### Check Staking Status

```bash
npm run stake:status
```

Shows comprehensive staking information including:
- Total balance
- Staked balance
- Unstaked balance
- Staking date
- When baking rights will appear

## Health Check Summary

**Quick health check (all in one):**

```bash
# Check connections
CONNECTIONS=$(curl -s http://localhost:9095/metrics | grep p2p_connections_active | awk '{print $2}')
echo "Connections: $CONNECTIONS"

# Check bootstrap status
BOOTSTRAPPED=$(curl -s http://localhost:9095/metrics | grep is_bootstrapped | awk '{print $2}')
if [ "$BOOTSTRAPPED" = "1.000000" ]; then
    echo "Status: ✅ Bootstrapped (synced)"
else
    echo "Status: ⏳ Still syncing"
fi

# Check block level
LEVEL=$(curl -s http://localhost:9095/metrics | grep head_level | awk '{print $2}')
echo "Block level: $LEVEL"
```

**Expected output:**
```
Connections: 15
Status: ✅ Bootstrapped (synced)
Block level: 17369883
```

## Troubleshooting Metrics

**Problem: Connections = 0**
- Solution: Wait a few minutes, check if node is starting
- If persists: Verify snapshot was imported

**Problem: Bootstrapped = 0 (not synced)**
- Solution: Wait longer (can take 1-2 hours with snapshot)
- Check logs: `npm run node:logs`

**Problem: Block level not increasing**
- Solution: Check if node is running: `docker ps`
- Check logs for errors: `npm run node:logs`

**Problem: No staking info**
- Solution: Run `npm run stake:status` to check
- If no staked balance: You need to stake funds first

## Resources

- **Block Explorer:** https://ghostnet.tzkt.io/ (check current network height)
- **Staking Guide:** [STAKING-GUIDE.md](STAKING-GUIDE.md)
- **Official Docs:** https://octez.tezos.com/docs/

---

**Note:** This guide focuses on essential metrics for testnet study mode. For production monitoring with Grafana/Prometheus, see archived monitoring stack in `archive/monitoring/`.

