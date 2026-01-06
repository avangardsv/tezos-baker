# Grafana Dashboard - Useful Metrics to Add

**Status**: Metrics now available (node has been running for 20+ hours)

All these metrics are from Grafazos dashboard expectations and are NOW working with your Octez v23.1 node.

---

## Quick Add: Top 6 Essential Metrics

These are the most important metrics from Grafazos that you should add first:

### 1. **Current Block Level** ⭐ (Most Important)

**In Grafana**:
- Click **Add** → **Visualization** → **prometheus**
- **Metric**: `octez_validator_chain_head_level{chain_id="NetXnHfVqm9ie"}`
- **Panel Title**: "Current Head Level"
- **Visualization**: Change to **Stat** (instead of Time series)
- **Standard options** → **Unit**: `none`
- **Value options** → **Show**: Last value
- **Apply**

**Current value**: 17,367,046
**What it shows**: Current blockchain height your node is at

---

### 2. **Bootstrap Status** ⭐

**In Grafana**:
- Click **Add** → **Visualization** → **prometheus**
- **Metric**: `octez_validator_chain_is_bootstrapped{chain_id="NetXnHfVqm9ie"}`
- **Panel Title**: "Bootstrap Status"
- **Visualization**: **Stat**
- **Value mappings**:
  - Click **Add value mappings**
  - Value: `1` → Display text: `✅ Bootstrapped` → Color: Green
  - Value: `0` → Display text: `⏳ Syncing` → Color: Red
- **Apply**

**Current value**: 1 (Bootstrapped ✅)

---

### 3. **Current Cycle** ⭐

**In Grafana**:
- **Metric**: `octez_validator_chain_head_cycle{chain_id="NetXnHfVqm9ie"}`
- **Panel Title**: "Current Cycle"
- **Visualization**: **Stat**
- **Apply**

**Current value**: 1967
**What it shows**: Current Tezos cycle (important for baker rights)

---

### 4. **Validation Errors** ⭐ (Health Check)

**In Grafana**:
- **Metric**: `octez_validator_block_validation_errors_count`
- **Panel Title**: "Validation Errors"
- **Visualization**: **Stat**
- **Thresholds**:
  - Base: Green (0 errors)
  - Add threshold: Red at 1 (any errors)
- **Apply**

**Current value**: 0 (Good ✅)
**What to watch**: Should always be 0

---

### 5. **Invalid Blocks** ⭐ (Health Check)

**In Grafana**:
- **Metric**: `octez_store_invalid_blocks`
- **Panel Title**: "Invalid Blocks"
- **Visualization**: **Stat**
- **Thresholds**: Green (0), Red (>0)
- **Apply**

**Current value**: 0 (Good ✅)

---

### 6. **Validated Blocks (Rate)** ⭐

**In Grafana**:
- **Metric**: `rate(octez_validator_block_validated_blocks_count[5m])`
- **Panel Title**: "Block Validation Rate"
- **Visualization**: **Time series** (graph)
- **Standard options** → **Unit**: `ops/sec` or `short`
- **Apply**

**What it shows**: How many blocks/sec the validator is processing

---

## Additional Useful Metrics (Medium Priority)

### 7. **Sync Status**
- **Metric**: `octez_validator_chain_synchronisation_status{chain_id="NetXnHfVqm9ie"}`
- **Value**: 1 = synced, 0 = syncing
- **Type**: Stat with value mappings

### 8. **Current Round**
- **Metric**: `octez_validator_chain_head_round{chain_id="NetXnHfVqm9ie"}`
- **Type**: Stat
- **Description**: Current Tenderbake consensus round

### 9. **Gas Consumed**
- **Metric**: `octez_validator_chain_head_consumed_gas{chain_id="NetXnHfVqm9ie"}`
- **Type**: Graph (time series)
- **Description**: Gas used in blocks over time

### 10. **Alternate Heads**
- **Metric**: `octez_store_alternate_heads_count`
- **Type**: Stat
- **Description**: Chain reorganizations (should be 0 or very low)

### 11. **Last Block Size**
- **Metric**: `octez_store_last_written_block_size`
- **Type**: Graph
- **Unit**: bytes (or `decbytes`)

### 12. **Validation Failed Count**
- **Metric**: `octez_validator_block_validation_failed_count`
- **Type**: Stat
- **Description**: Failed validations (some failures are normal during sync)
- **Current**: 121 (normal for syncing node)

---

## Important Note About chain_id Label

Many validator metrics have a label `{chain_id="NetXnHfVqm9ie"}` (Ghostnet).

**Two ways to query**:

**Option 1 - Specific** (recommended):
```
octez_validator_chain_head_level{chain_id="NetXnHfVqm9ie"}
```

**Option 2 - Any chain**:
```
octez_validator_chain_head_level
```

Use Option 1 if you only run Ghostnet (prevents issues if you add mainnet later).

---

## Dashboard Layout Recommendation

**Row 1: Health Status** (4 panels, Stat visualization)
- Bootstrap Status (1 or 0)
- Validation Errors (should be 0)
- Invalid Blocks (should be 0)
- Sync Status (1 or 0)

**Row 2: Current State** (4 panels, Stat visualization)
- Current Block Level (17,367,046)
- Current Cycle (1967)
- Current Round
- Alternate Heads (should be 0)

**Row 3: Network** (already have these ✓)
- Active Peers (25)
- Current Inflow (bytes/sec)
- Total Data Sent
- Total Data Received

**Row 4: Performance** (graphs)
- Block Validation Rate (ops/sec)
- Gas Consumed (over time)
- Last Block Size (bytes)
- Checkpoint Level

**Row 5: Mempool** (already have ✓)
- Validated Operations
- (could add: pending_refused, pending_outdated)

---

## Quick Copy-Paste: All Essential Metrics

For rapid dashboard building, here are all 6 essential metrics:

```
octez_validator_chain_head_level{chain_id="NetXnHfVqm9ie"}
octez_validator_chain_is_bootstrapped{chain_id="NetXnHfVqm9ie"}
octez_validator_chain_head_cycle{chain_id="NetXnHfVqm9ie"}
octez_validator_block_validation_errors_count
octez_store_invalid_blocks
rate(octez_validator_block_validated_blocks_count[5m])
```

---

## Why Grafazos Dashboard Didn't Work

The Grafazos dashboard expects these exact metrics with these exact names. Your node NOW has them all (after running 20+ hours and being bootstrapped).

**The issue was timing**:
- When you first tried Grafazos: Node just started, metrics empty
- Now: Node running 20h, bootstrapped, all metrics available

**You could try Grafazos again**, but your custom dashboard is cleaner and you control what's shown.

---

## Current Dashboard vs Full Grafazos

**Your current dashboard (6 panels)**:
- Active Peers ✓
- Total Data Sent ✓
- Total Data Received ✓
- Checkpoint Level ✓
- Validated Operations ✓
- Current Inflow ✓

**Add these 6 essential metrics** → 12 total panels:
- Current Block Level
- Bootstrap Status
- Current Cycle
- Validation Errors
- Invalid Blocks
- Block Validation Rate

**Total**: 12 panels covering all critical baker/validator metrics

**Grafazos dashboard**: 25+ panels (many redundant or too technical)

---

## Verification: Check Metrics Work

Before adding to Grafana, verify in Prometheus:

```bash
# Test in Prometheus web UI (http://localhost:9090)
# Or via command line:

# Block level
curl -s 'http://localhost:9090/api/v1/query?query=octez_validator_chain_head_level' | jq '.data.result[0].value[1]'

# Bootstrap status
curl -s 'http://localhost:9090/api/v1/query?query=octez_validator_chain_is_bootstrapped' | jq '.data.result[0].value[1]'

# Current cycle
curl -s 'http://localhost:9090/api/v1/query?query=octez_validator_chain_head_cycle' | jq '.data.result[0].value[1]'
```

All should return values (not empty).

---

## Next Steps

1. **Add the 6 essential metrics** (15 minutes)
2. **Arrange in rows** for clarity (5 minutes)
3. **Save dashboard** (1 minute)
4. **Total time**: ~20 minutes

**Result**: Complete baker monitoring dashboard with all critical Grafazos metrics.
