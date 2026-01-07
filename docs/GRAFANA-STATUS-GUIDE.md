# Grafana Status Check Guide

Where to find each status metric in Grafana dashboards.

## Dashboard Access

**Grafana URL:** http://localhost:3000  
**Login:** admin / tezos_monitoring_2026  
**Dashboard:** Import "Octez full" from `data/grafazos/output/octez-full.json`

---

## Status Table → Grafana Panels

### 1. Node Synced (Level, Bootstrapped)

**Grafana Location:**
- **Panel:** "Bootstrap status" (top of dashboard, Node stats section)
- **Panel:** "Current head level" (shows block level)
- **Panel:** "Sync status" (if available)

**Metrics:**
- `octez_validator_chain_is_bootstrapped` = 1.0 (synced) or 0.0 (syncing)
- `octez_node_head_level` = Current block level

**Quick Check:**
```bash
curl -s http://localhost:9095/metrics | grep -E "is_bootstrapped|head_level"
```

**Expected:**
- Bootstrapped: `1.000000`
- Level: Should match network height (check https://ghostnet.tzkt.io/)

---

### 2. Baker Active (Producing Attestations)

**Grafana Location:**
- **Panel:** "Node logs" (Logs section)
- **Panel:** "Baker logs" (if separate panel)

**What to Look For:**
- Log messages showing "attesting" or "baking"
- Recent activity in logs panel
- No errors in baker logs

**Quick Check:**
```bash
npm run baker:logs
# Look for: "attesting" or "baking" messages
```

**Alternative:**
```bash
docker logs tezos-baker --tail 50 | grep -E "attesting|baking"
```

---

### 3. RPC Status (Bound to 0.0.0.0:8732)

**Grafana Location:**
- **Not directly shown** in Grafazos dashboards
- Check via direct RPC call

**Quick Check:**
```bash
# Test RPC endpoint
curl -s http://localhost:8732/chains/main/chain_id
# Should return: "NetXnHfVqm9ie"

# Check if metrics endpoint works
curl -s http://localhost:9095/metrics | head -5
```

**Expected:** Both endpoints should respond without errors.

---

### 4. P2P Connections (25+ connections)

**Grafana Location:**
- **Panel:** "P2P total connections" (P2P stats section)
- **Panel:** "Active Peers" (shows connection count)
- **Panel:** "P2P peers connections" (detailed breakdown)

**Metrics:**
- `octez_p2p_connections_active` = Number of active connections
- `octez_p2p_connections_outgoing` = Outgoing connections
- `octez_p2p_connections_incoming` = Incoming connections

**Quick Check:**
```bash
curl -s http://localhost:9095/metrics | grep p2p_connections_active
```

**Expected:**
- Healthy: 10-30 connections
- Minimum: 5 connections
- Your status: 25+ (excellent!)

---

### 5. Staking (11,999.5 ꜩ staked)

**Grafana Location:**
- **Not in Grafazos dashboards** (staking is Tezos protocol level, not node metrics)

**Check Via:**
```bash
npm run stake:status
```

**Or Direct RPC:**
```bash
# Get your address first
npm run account:show

# Then query staking (replace YOUR_ADDRESS)
curl -s http://localhost:8732/chains/main/blocks/head/context/contracts/YOUR_ADDRESS | jq '.staked_balance'
```

**Expected:**
- Staked balance: 11,999.5 ꜩ (or your staked amount)
- Total balance: Includes staked + unstaked

---

### 6. Baking Rights (Has Attesting Rights)

**Grafana Location:**
- **Panel:** Check baker logs for "attesting" messages
- **Panel:** "Baker rights" (if available in dashboard)

**Quick Check:**
```bash
# Check baking rights via RPC
npm run account:show  # Get your address
curl -s "http://localhost:8732/chains/main/blocks/head/helpers/baking_rights?delegate=YOUR_ADDRESS" | jq '. | length'
```

**Or Check Logs:**
```bash
docker logs tezos-baker --tail 100 | grep -E "attesting|rights"
```

**Expected:**
- If you have rights: Logs show "attesting" messages
- If no rights: Logs show "no attesting rights" (normal, wait 14-21 days)

---

### 7. Operations (Submitting to Chain)

**Grafana Location:**
- **Panel:** "Head operations" (Node stats section)
- **Panel:** "Mempool status" (P2P stats section)
- **Panel:** "Mempool status" table (shows validated/refused operations)

**Metrics:**
- `octez_mempool_validated` = Operations validated
- `octez_mempool_refused` = Operations refused
- `octez_validator_block_operations_per_pass` = Operations per block

**Quick Check:**
```bash
curl -s http://localhost:9095/metrics | grep -E "mempool|operations"
```

**Expected:**
- Validated operations > 0 (if you're submitting)
- Refused operations (some refusal is normal)

---

## Complete Status Check in Grafana

### Step-by-Step:

1. **Open Grafana:** http://localhost:3000
2. **Go to Dashboard:** "Octez full" (or "Octez basic")
3. **Check Node Stats Section:**
   - Bootstrap status = ✅ (green/1.0)
   - Current head level = Recent (matches network)
   - Sync status = Synced

4. **Check P2P Stats Section:**
   - P2P total connections = 25+ (your case)
   - Active peers = 10-30

5. **Check Logs Section:**
   - Node logs = Recent activity
   - Look for "attesting" messages (baker activity)

6. **Check Mempool Section:**
   - Operations validated = Shows activity
   - Mempool status = Active

---

## Quick Status Dashboard (Custom)

**Create a custom dashboard with all status metrics:**

1. **In Grafana:** Create new dashboard
2. **Add panels:**
   - Bootstrap status: `octez_validator_chain_is_bootstrapped`
   - Head level: `octez_node_head_level`
   - Connections: `octez_p2p_connections_active`
   - Operations: `octez_mempool_validated`

3. **Save as:** "Tezos Status Overview"

---

## Alternative: Command-Line Status Check

**If Grafana is not running, use direct commands:**

```bash
# Complete status check
echo "=== Node Status ==="
curl -s http://localhost:9095/metrics | grep -E "is_bootstrapped|head_level" | head -2

echo "=== P2P Connections ==="
curl -s http://localhost:9095/metrics | grep p2p_connections_active

echo "=== Staking Status ==="
npm run stake:status

echo "=== Baker Logs (last 10 lines) ==="
docker logs tezos-baker --tail 10 | grep -E "attesting|baking|rights"
```

---

## Troubleshooting

**Grafana not accessible?**
```bash
# Check if Grafana is running
docker ps | grep grafana

# If not running, start monitoring stack
cd monitoring && docker-compose up -d
```

**Dashboard not showing data?**
- Verify Prometheus is scraping: http://localhost:9090/targets
- Check node metrics endpoint: http://localhost:9095/metrics
- Verify datasource UID matches dashboard

**Missing panels?**
- Import dashboard from: `data/grafazos/output/octez-full.json`
- Or use "Octez basic" dashboard (simpler)

---

## Summary

| Status Item | Grafana Location | Alternative Check |
|-------------|------------------|-------------------|
| Node Synced | Bootstrap status panel | `curl metrics | grep bootstrapped` |
| Baker Active | Logs panel | `npm run baker:logs` |
| RPC Status | Not in dashboard | `curl http://localhost:8732/chain_id` |
| P2P Connections | P2P stats section | `curl metrics | grep connections` |
| Staking | Not in dashboard | `npm run stake:status` |
| Baking Rights | Logs panel | `docker logs tezos-baker` |
| Operations | Mempool section | `curl metrics | grep mempool` |

---

**Note:** Some metrics (staking, RPC status) are not in Grafazos dashboards because they're Tezos protocol-level, not node metrics. Use command-line tools for these.

