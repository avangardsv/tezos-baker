# Tezos Staking Guide (Study Mode)

This guide explains Tezos staking mechanics and how to use the staking scripts for educational purposes.

## Table of Contents

1. [What is Staking?](#what-is-staking)
2. [Why Staking is Required](#why-staking-is-required)
3. [Staking vs Delegation](#staking-vs-delegation)
4. [The Staking Lifecycle](#the-staking-lifecycle)
5. [Using the Staking Scripts](#using-the-staking-scripts)
6. [Common Scenarios](#common-scenarios)
7. [Troubleshooting](#troubleshooting)

---

## What is Staking?

**Staking** is the process of locking your XTZ tokens to participate in Tezos consensus and earn rewards.

### Key Concepts:

- **Liquid Balance**: XTZ you can spend immediately
- **Staked Balance**: XTZ locked for baking/attesting (cannot spend)
- **Full Balance**: Liquid + Staked combined

### Analogy:
Think of staking like depositing money in a CD (Certificate of Deposit):
- You lock funds for a period
- The locked funds earn rewards
- To access them, you must unstake (withdraw) and wait for the unlock period

---

## Why Staking is Required

### The Problem We Discovered:

When comparing two bakers:
- **Baker A** (comparison): 6,010 ꜩ total, **6,009 ꜩ staked** → 954 attestations in 4 days ✅
- **Baker B** (yours): 11,999 ꜩ total, **0 ꜩ staked** → 0 attestations in 17 days ❌

### Why?

Tezos uses **Proof-of-Stake** consensus. The protocol:

1. **Calculates baking rights** based on **staked balance**, not total balance
2. **Assigns rights proportionally** to stake size
3. **Distributes rewards** for successful attestations and blocks

**Formula:**
```
Your Rights = (Your Staked Balance / Total Network Staked) × Total Available Rights
```

**Without staking:**
```
Your Rights = (0 ꜩ / Total Network Staked) × Total Available Rights = 0
```

---

## Staking vs Delegation

### Delegation (What you've done):
- Points your funds to a baker
- Required for both self-baking and delegating to others
- Instant operation
- Command: `npm run delegate:register`

### Staking (What you need to do):
- Locks your funds to actually participate
- Required AFTER delegation to receive rights
- Has a delay before rights are assigned (5-7 cycles)
- Command: `npm run stake:all`

### Timeline:
```
1. Register as delegate   ✅ You did this
      ↓ (instant)
2. Stake funds            ❌ You skipped this
      ↓ (wait 14-21 days)
3. Receive baking rights  ← You're stuck here
      ↓
4. Earn rewards
```

---

## The Staking Lifecycle

### Phase 1: Staking (Day 0)
```bash
npm run stake:all
```

**What happens:**
- Liquid XTZ → Staked XTZ (frozen)
- Transaction included in blockchain
- Balance changes immediately
- Rights assignment begins in background

**Verification:**
```bash
npm run stake:status
# Shows: Staked: 11,999 ꜩ ✅
```

### Phase 2: Waiting for Rights (Days 1-21)
**Duration:** ~5-7 cycles (14-21 days)

**Why the wait?**
- Tezos protocol calculates rights in advance
- Prevents gaming the system
- Ensures stable validator set

**What to do:**
```bash
# Check periodically (every few days)
npm run baker:rights
npm run stake:status

# Monitor on blockchain explorer
https://ghostnet.tzkt.io/tz1Wp2H3WFGDsKXYJWeYLmJaFeWp51fH1rWi
```

### Phase 3: Active Baking (Day 21+)
**Once you have rights:**
- Baker automatically attests blocks (~every 10 seconds)
- Occasionally bakes blocks (when selected)
- Earns rewards (small amounts on testnet)

**Monitoring:**
```bash
npm run baker:logs          # See live baking activity
npm run monitor             # Dashboard view
npm run baker:status        # Check baker health
```

### Phase 4: Unstaking (When you want to stop)
```bash
# Step 1: Initiate unstaking
npm run unstake:all

# Step 2: Wait 4 cycles (~12 days)

# Step 3: Finalize and get liquid XTZ back
npm run unstake:finalize
```

**Note:** During unstaking wait period, your funds are still frozen but you stop earning new rights.

---

## Using the Staking Scripts

### 1. Check Current Status
```bash
npm run stake:status
```

**Output:**
- Current balances (liquid vs staked)
- Delegation info
- RPC data for deep dive
- Warning if not staked
- Next steps suggestions

**Educational value:** Shows complete picture of your baker's state

---

### 2. Stake All Funds (Recommended for Testnet)
```bash
npm run stake:all
```

**What it does:**
- Stakes: `liquid balance - 0.5 ꜩ`
- Reserves 0.5 ꜩ for transaction fees
- Shows before/after balances
- Educational explanations throughout

**When to use:** Initial setup on testnet (no risk)

---

### 3. Stake Minimum (Conservative)
```bash
npm run stake:minimum
```

**What it does:**
- Stakes exactly 6,000 ꜩ
- Minimum required for baking rights
- Keeps rest liquid

**When to use:** Testing or preserving liquidity

---

### 4. Stake Half (Balanced)
```bash
npm run stake:half
```

**What it does:**
- Stakes 50% of liquid balance
- Keeps 50% liquid for flexibility

**When to use:** Mainnet testing with real funds (not recommended on mainnet without hardware wallet)

---

### 5. Custom Amount (Advanced)
```bash
npm run stake:custom
```

**What it does:**
- Interactive prompts
- Choose preset or enter custom amount
- Educational explanations
- Validation checks

**When to use:** Learning about the staking process

**Example interaction:**
```
Available presets:
  1) All funds       (11999.5 ꜩ)
  2) Half funds      (5999.75 ꜩ)
  3) Minimum stake   (6,000 ꜩ)
  4) Custom amount

Choose an option (1-4): 3

STAKING SUMMARY
Amount to stake: 6000 ꜩ

What happens when you stake:
1. Your liquid XTZ becomes 'staked' (frozen)
2. Staked XTZ cannot be spent immediately
3. In 5-7 cycles (~14-21 days), you'll receive baking/attesting rights
4. Your baker will automatically use these rights to earn rewards
5. To unstake: 'npm run unstake:all' → wait 4 cycles → 'npm run unstake:finalize'

Do you want to proceed? (yes/no):
```

---

### 6. Check Staked Balance (Quick)
```bash
npm run stake:balance
```

**Output:** Just the staked amount, e.g., `0 ꜩ` or `6000 ꜩ`

**When to use:** Quick status check in scripts

---

### 7. Unstake All Funds
```bash
npm run unstake:all
```

**What it does:**
- Initiates unstaking of ALL staked funds
- Starts 4-cycle countdown (~12 days)
- Funds remain frozen during countdown

**When to use:**
- Shutting down baker
- Moving to different setup
- Migrating to mainnet

**Important:** You'll continue to have rights during countdown period, then gradually lose them.

---

### 8. Finalize Unstaking
```bash
npm run unstake:finalize
```

**What it does:**
- Transfers unstaked funds → liquid balance
- Only works after 4-cycle wait period
- Makes funds spendable again

**When to use:** 4+ cycles after running `unstake:all`

---

## Common Scenarios

### Scenario 1: Fresh Setup (Your Case)
**Current state:**
- ✅ Node running and synced
- ✅ Registered as delegate
- ✅ Have 11,999 ꜩ balance
- ❌ 0 ꜩ staked → No rights

**Fix:**
```bash
# 1. Check current status
npm run stake:status

# 2. Stake all funds (testnet = no risk)
npm run stake:all

# 3. Verify
npm run stake:status
# Should show: Staked: ~11,999 ꜩ ✅

# 4. Wait 14-21 days, check progress periodically
npm run baker:rights
```

**Expected timeline:**
- Day 0: Stake funds
- Days 1-21: Wait for rights (check weekly)
- Day 21+: Start seeing attestations
- Day 22+: Check explorer for first attestations

---

### Scenario 2: Testing Unstaking
**Goal:** Learn the unstaking process

```bash
# 1. Check current stake
npm run stake:status

# 2. Initiate unstaking
npm run unstake:all
# Output: "Unstaking initiated. Wait 4 cycles (~12 days)"

# 3. Check status during wait
npm run stake:status
# Shows unstaked amount and countdown

# 4. After 12+ days, finalize
npm run unstake:finalize

# 5. Verify funds are liquid again
npm run account:balance
npm run stake:balance  # Should be 0 ꜩ
```

---

### Scenario 3: Partial Staking Study
**Goal:** Understand how partial staking affects rights

```bash
# Experiment 1: Stake minimum
npm run stake:minimum  # 6,000 ꜩ
# Wait 21 days, observe attestation frequency

# Experiment 2: Stake more
npm run stake:custom   # Add 3,000 ꜩ more
# Wait 21 days, observe increased attestations

# Experiment 3: Compare with full stake
npm run stake:all      # Stake remaining
# Wait 21 days, observe maximum attestations
```

**Learning:** Rights are proportional to stake size

---

### Scenario 4: Monitoring Active Baker
**After you have rights (21+ days post-staking):**

```bash
# Daily check
npm run monitor

# Watch live attestations
npm run baker:logs

# Check specific status
npm run stake:status
npm run baker:status

# View on blockchain
open https://ghostnet.tzkt.io/tz1Wp2H3WFGDsKXYJWeYLmJaFeWp51fH1rWi/operations/
```

---

## Troubleshooting

### Issue 1: "0 ꜩ staked but I ran stake:all"

**Possible causes:**
1. Transaction failed (check node logs)
2. Insufficient liquid balance
3. Transaction not included yet (wait 30 seconds)

**Debug:**
```bash
# Check if transaction succeeded
npm run node:logs | tail -50

# Re-check balances
npm run stake:status

# Try again with smaller amount
npm run stake:custom
# Enter amount like 6000
```

---

### Issue 2: "No baking rights after 3 weeks"

**Check:**
```bash
# 1. Verify you have staked balance
npm run stake:balance
# Should show > 0 ꜩ

# 2. Check delegate status
npm run delegate:status
# Should show: deactivated: false

# 3. Check baker is running
npm run ps
# Should show tezos-baker container

# 4. Check for rights
npm run baker:rights
```

**Common causes:**
- Baker got deactivated (missed attestations)
- Staked amount too low (< 6,000 ꜩ)
- Haven't waited full 5-7 cycles

**Fix:**
```bash
# If deactivated, re-register
npm run delegate:register

# Re-stake
npm run stake:all

# Wait another 14-21 days
```

---

### Issue 3: "Transaction failed: insufficient balance"

**Cause:** Trying to stake more than you have

**Solution:**
```bash
# Check available liquid balance
npm run account:balance

# Stake slightly less (leave buffer for fees)
npm run stake:custom
# Enter amount = (balance - 1 ꜩ)
```

---

### Issue 4: "Understanding balance types"

```bash
# Run comprehensive status
npm run stake:status
```

**Example output:**
```
Total Balance: 11,999.998495 ꜩ
Full Balance (includes staked): 11,999.998495 ꜩ
Staked Balance: 0 ꜩ

Total = Full = Liquid + Staked
11,999.998495 = 11,999.998495 = 11,999.998495 + 0
```

**After staking 6,000:**
```
Total Balance: 5,999.998495 ꜩ  (liquid only)
Full Balance: 11,999.998495 ꜩ  (liquid + staked)
Staked Balance: 6,000 ꜩ         (frozen)

Total = Liquid
Full = Liquid + Staked
11,999.998495 = 5,999.998495 + 6,000
```

---

## Advanced: Understanding Cycles

### What is a Cycle?
- **Duration:** ~2.8 days (8,192 blocks on Ghostnet)
- **Purpose:** Time unit for protocol operations

### Cycle-Based Operations:

| Operation | Cycles | Days |
|-----------|--------|------|
| Rights assignment | 5-7 | 14-21 |
| Unstaking delay | 4 | ~12 |
| Baker grace period | 5 | ~14 |
| Snapshot timing | Every cycle | ~2.8 |

### Checking Current Cycle:
```bash
curl -s http://127.0.0.1:8732/chains/main/blocks/head/metadata | jq '.level_info.cycle'
```

---

## Study Exercises

### Exercise 1: Full Staking Workflow
1. Check initial status
2. Stake all funds
3. Verify balances changed
4. Check status daily for 1 week
5. Document observations

### Exercise 2: Unstaking Mechanics
1. Stake 6,000 ꜩ
2. Unstake all
3. Try to finalize immediately (should fail)
4. Wait 4 cycles
5. Finalize successfully
6. Document timeline

### Exercise 3: Rights Observation
1. Stake all funds
2. Record current cycle number
3. Check baker:rights daily
4. Note when first rights appear
5. Calculate actual delay in days

### Exercise 4: Comparison Study
1. Check tz3VuQRX...KMHm baker stats
2. Stake equal amount
3. Compare attestation frequency after 21 days
4. Analyze difference based on stake size

---

## Key Takeaways

1. **Staking ≠ Delegation**
   - Delegation: Points funds to a baker
   - Staking: Locks funds to participate

2. **Rights are proportional to stake**
   - 2x stake → 2x rights → 2x rewards

3. **Patience required**
   - Initial: 14-21 days for rights
   - Unstaking: 12 days to unlock

4. **Testnet = Safe learning**
   - No real money at risk
   - Same mechanics as mainnet
   - Perfect for understanding

5. **Mainnet differences**
   - Real money (6,000 XTZ ≈ $22,000+)
   - Requires hardware wallet
   - Slashing possible (future protocols)
   - 24/7 uptime critical

---

## Resources

- **Scripts:**
  - `npm run stake:status` - Comprehensive status
  - `npm run stake:all` - Quick staking
  - `npm run help` - All commands

- **Explorer:**
  - Your baker: https://ghostnet.tzkt.io/tz1Wp2H3WFGDsKXYJWeYLmJaFeWp51fH1rWi
  - Comparison baker: https://ghostnet.tzkt.io/tz3VuQRXCAh8RVH93xYBwkBoaZBNCET9KMHm

- **Documentation:**
  - Tezos staking docs: https://opentezos.com/tezos-basics/liquid-proof-of-stake
  - Octez baker guide: https://tezos.gitlab.io/active/proof_of_stake.html

---

## Next Steps

1. **Immediate:** Run `npm run stake:all` to fix your current setup
2. **Short-term:** Monitor daily with `npm run stake:status`
3. **Long-term:** Study comparison baker to understand expected performance
4. **Advanced:** Experiment with partial unstaking/restaking

---

**Remember:** This is study mode on testnet. Take risks, experiment, learn. Mistakes here are educational, not expensive!
