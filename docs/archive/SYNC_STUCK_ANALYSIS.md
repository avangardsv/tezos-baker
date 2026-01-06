# Node Sync Stuck - Root Cause Analysis

**Status**: Node has been stuck at block 17,312,258 for ~22 hours
**Current blockchain height**: 17,332,308
**Gap**: 20,050 blocks behind (~22 hours of blocks)
**Discovery date**: 2026-01-02

---

## 🔍 ROOT CAUSE

### The Problem
Your node is stuck in a **validation deadlock** trying to fetch operations for block:
```
BKzSDZg3vvE3p6oenJY6TjCSFansq7q1B8jNPpWiDozJxLgvmR1:3
```

### Error Pattern
```
ERROR │ Fetch of operations BKzSDZg3vvE3p6oenJY6TjCSFansq7q1B8jNPpWiDozJxLgvmR1:3 timed out
ERROR │ worker crashed [validator-peer]
```

This error repeats **hundreds of times** - the node keeps trying the same block and failing.

### Why This Happens

**1. Corrupt/Invalid Block Operations**
- One specific block (17,312,258 → 17,312,259) has operations the node cannot fetch
- All peers timeout when trying to provide this data
- The block exists but its operations are unavailable or malformed

**2. Validator Deadlock**
- Tezos node validator gets stuck on this specific block
- Cannot move forward (missing operations for next block)
- Cannot move backward (already committed previous block)
- Keeps retrying the same failed operation in an infinite loop

**3. Peer Issues**
- Your node has 20-24 peers connected
- All peers either:
  - Don't have the operations for this block
  - Have corrupted data for this block
  - Are timing out when trying to serve it

---

## 🎯 WHY YOUR MONITORING MISSED IT

### False Positive
Your health check **initially reported [OK]** because it only checked:
- ✅ Peer count (20-24 peers = healthy)
- ✅ No errors in logs (only warnings about fetching)
- ❌ **DID NOT CHECK**: Block sync status vs actual blockchain

### The Fix We Implemented
Added sync verification:
```bash
# Calculate how far behind the node is
SYNC_LAG=$(get_sync_lag "$NODE_TIMESTAMP")

# Alert if >1 hour behind
if [ "$SYNC_LAG" -gt 3600 ]; then
    ALERT_LEVEL="critical"
fi
```

Now correctly reports: `[CRITICAL] Node stuck 22h behind blockchain`

---

## 💡 HOW TO FIX NOW

### Option 1: Restart Node (Fast, May Fail Again)
**Time**: 5 minutes
**Risk**: Might get stuck on same block again

```bash
npm run node:stop
npm run node:start
# Wait and check if it syncs past block 17,312,258
```

**When it works**:
- If the block data was temporarily unavailable
- If peers now have correct data

**When it fails**:
- If the block is truly corrupted in local storage
- If all network peers have bad data

---

### Option 2: Import Fresh Snapshot (Recommended)
**Time**: 30-60 minutes
**Risk**: None, guaranteed to work

This completely bypasses the problematic block by starting from a recent snapshot.

```bash
# 1. Stop containers
npm run node:stop
npm run baker:stop

# 2. Backup current data (optional)
mv data data-backup-$(date +%Y%m%d)

# 3. Download snapshot (~1.6GB, takes 10-15 min)
npm run snapshot:download

# 4. Re-init node
npm run node:init
npm run node:identity
npm run node:version

# 5. Import snapshot (takes 10-20 min)
npm run snapshot:import

# 6. Restart everything
npm run node:start
# Wait 2-3 minutes for node to start
npm run baker:start

# 7. Verify
npm run monitor
```

**Why this works**:
- Snapshot is from a recent block (likely 17,330,000+)
- Completely bypasses the corrupt block 17,312,258
- Starts fresh with verified blockchain state

---

### Option 3: Clear Just the Context (Advanced)
**Time**: 15 minutes
**Risk**: Medium

```bash
npm run node:stop
# Remove context but keep identity
rm -rf data/context data/store
# Re-init and re-sync from peers
npm run node:version
npm run node:start
```

**When to use**:
- If you want to try fixing without full snapshot
- If snapshot download is too slow

**Risk**:
- Node will re-sync from scratch or from peers
- Might hit same corrupt block again

---

## 🛡️ HOW TO PREVENT IN FUTURE

### 1. ✅ Enhanced Monitoring (DONE)
**What we implemented**:
- Sync lag detection (alerts if >1 hour behind)
- Block height tracking
- Automated GitHub notifications

**What it catches**:
- Node stuck syncing
- Node falling behind blockchain
- Network issues causing sync delays

**Runs**: Every hour via cron

---

### 2. 📊 Add Sync Progress Tracking
**What to add**: Track sync velocity (blocks/minute)

Create `/scripts/track-sync-velocity.sh`:
```bash
#!/bin/bash
# Track how fast node is syncing

CURRENT_LEVEL=$(rpc_get_block_level)
sleep 60
NEW_LEVEL=$(rpc_get_block_level)

BLOCKS_PER_MIN=$((NEW_LEVEL - CURRENT_LEVEL))

if [ "$BLOCKS_PER_MIN" -lt 10 ]; then
    echo "WARNING: Slow sync - only $BLOCKS_PER_MIN blocks/min"
    echo "Expected: 30-60 blocks/min for catching up"
fi
```

**Add to health check**:
```bash
# Alert if sync velocity is zero (stuck)
if [ "$SYNC_LAG" -gt 600 ] && [ "$BLOCKS_PER_MIN" -eq 0 ]; then
    ALERT_LEVEL="critical"
    ALERT_MESSAGE="Node completely stuck - no sync progress"
fi
```

---

### 3. 🔄 Automated Recovery
**Auto-restart on stuck detection**:

Add to health check:
```bash
# If stuck >6 hours, auto-restart node
if [ "$SYNC_LAG" -gt 21600 ]; then
    log_warn "Node stuck >6h, attempting auto-restart"
    docker restart tezos-node

    # Wait and check if restart helped
    sleep 60
    NEW_SYNC_LAG=$(get_sync_lag)

    if [ "$NEW_SYNC_LAG" -lt "$SYNC_LAG" ]; then
        log_success "Auto-restart successful, node is syncing"
    else
        log_error "Auto-restart failed, manual intervention needed"
        # Send critical alert
    fi
fi
```

---

### 4. 📈 Better Logging
**What to log**:
```bash
# In health check, log to persistent file
echo "$(date),${NODE_LEVEL},${SYNC_LAG},${PEERS}" >> logs/sync-history.csv

# Analyze trends
tail -100 logs/sync-history.csv | awk -F',' '{print $3}' | gnuplot
```

**Catches**:
- Gradual slowdown before complete stop
- Patterns (e.g., stuck every week at same time)
- Correlation with peer count drops

---

### 5. 🔔 Escalating Alerts
**Progressive notifications**:
```bash
# 10 min behind = INFO (no notification)
# 1 hour behind = WARNING (GitHub issue)
# 6 hours behind = CRITICAL (issue + auto-restart attempt)
# 12 hours behind = EMERGENCY (issue + email/SMS if configured)
```

---

### 6. 🗓️ Scheduled Snapshot Refreshes
**Preventive maintenance**:
```bash
# Every week, import fresh snapshot
# Prevents accumulation of validation issues
0 2 * * 0 /path/to/weekly-snapshot-refresh.sh
```

Script:
```bash
#!/bin/bash
# weekly-snapshot-refresh.sh

npm run node:stop
npm run baker:stop
npm run snapshot:download
npm run snapshot:import
npm run node:start
sleep 180
npm run baker:start
```

---

## 📋 IMMEDIATE ACTION PLAN

### For Now (Fix Current Issue):
1. ✅ Run health check to document current state
2. ⚠️ **Choose Option 2** (snapshot import - recommended)
3. ✅ Follow snapshot import steps above
4. ✅ Verify node is syncing with `npm run monitor`
5. ✅ Check baker is running with `npm run baker:status`

### For Future (Prevention):
1. ✅ Enhanced monitoring is already running (cron every hour)
2. 📝 Add sync velocity tracking (optional improvement)
3. 🔄 Add auto-restart on stuck detection (optional)
4. 🗓️ Schedule weekly snapshot refreshes (optional)

---

## 🔬 DEBUGGING CHECKLIST FOR FUTURE ISSUES

When node sync issues occur:

### 1. Check Basic Health
```bash
npm run health:check     # Overall status
npm run monitor          # Detailed view
npm run node:head        # Current block
```

### 2. Check Logs for Patterns
```bash
# Last 100 errors
docker logs tezos-node 2>&1 | grep ERROR | tail -100

# Stuck on specific block?
docker logs tezos-node 2>&1 | grep "timed out" | tail -20

# Peer connection issues?
docker logs tezos-node 2>&1 | grep "disconnected" | tail -20
```

### 3. Check System Resources
```bash
df -h                    # Disk space
docker stats tezos-node  # CPU/Memory
du -sh data/             # Data directory size
```

### 4. Compare with Network
```bash
# Your node
curl -s http://127.0.0.1:8732/chains/main/blocks/head/header | jq .level

# Actual blockchain
curl -s https://rpc.ghostnet.teztnets.com/chains/main/blocks/head/header | jq .level

# Calculate gap
```

### 5. Check Peer Quality
```bash
npm run node:peers       # List all peers
npm run node:connections # Count connections
```

### 6. Decision Tree
```
Is sync lag < 1 hour?
  YES → Monitor, likely catching up
  NO  → Is it growing?
    YES → Node stuck, proceed to fix
    NO  → Slow sync, check resources/peers

Is same error repeating?
  YES → Validation deadlock, need snapshot
  NO  → Network issues, try restart

Are peers connected?
  YES → Validation issue (use snapshot)
  NO  → Network issue (check firewall/ports)
```

---

## 📊 METRICS TO TRACK

Essential metrics for early detection:

1. **Sync Lag** (seconds behind blockchain)
   - Current: ✅ Tracked in health check
   - Alert threshold: >3600s (1 hour)

2. **Block Height Delta** (your level - network level)
   - Current: ❌ Not tracked
   - Should track: Block gap over time

3. **Sync Velocity** (blocks/minute)
   - Current: ❌ Not tracked
   - Expected: 30-60 blocks/min when catching up
   - Alert if: <10 blocks/min or 0 blocks/min

4. **Peer Count**
   - Current: ✅ Tracked
   - Threshold: <20 peers = warning

5. **Error Rate**
   - Current: ✅ Tracked
   - Threshold: >20 errors/10min = warning

6. **Validation Timeouts**
   - Current: ❌ Not tracked
   - Should alert: If same block fails >10 times

---

## 🎓 LESSONS LEARNED

1. **Peer count ≠ Health**
   - 24 peers doesn't mean syncing correctly
   - Must check actual sync progress

2. **Errors vs Warnings**
   - "Fetch timeout" seems like warning
   - But repeated timeouts = critical deadlock

3. **Validation Can Deadlock**
   - Tezos node can get stuck on single bad block
   - Cannot recover without external intervention

4. **Monitoring Must Check Progress**
   - Not just "is it running?"
   - But "is it moving forward?"

5. **Snapshots Are Recovery Tool**
   - Fastest way to bypass corrupted state
   - Should be part of regular maintenance

---

## 🔗 REFERENCES

- Tezos Snapshot Service: https://snapshots.tzinit.org/
- Ghostnet RPC: https://rpc.ghostnet.teztnets.com/
- Tezos Node Troubleshooting: https://tezos.gitlab.io/user/node-troubleshooting.html

