# Staking Quick Start

## Why You Need to Stake

**Problem:** You have 11,999 ꜩ but 0 attestations after 17 days.

**Cause:** Tezos assigns baking rights based on **staked balance**, not total balance.

**Solution:** Stake your funds.

---

## Quick Fix (3 Commands)

```bash
# 1. Check current status
npm run stake:status

# 2. Stake all funds (recommended for testnet)
npm run stake:all

# 3. Verify
npm run stake:status
# Should show: Staked: ~11,999 ꜩ ✅
```

**Timeline:**
- Day 0: Stake funds ✅
- Days 1-21: Wait for rights (check weekly with `npm run baker:rights`)
- Day 21+: Start seeing attestations

---

## All Staking Commands

```bash
# Status
npm run stake:status        # Full status report
npm run stake:balance       # Quick check

# Stake funds
npm run stake:all           # Stake all (recommended for testnet)
npm run stake:half          # Stake 50%
npm run stake:minimum       # Stake 6,000 ꜩ
npm run stake:custom        # Interactive mode

# Unstake funds
npm run unstake:all         # Start unstaking
# ... wait 12 days ...
npm run unstake:finalize    # Complete unstaking
```

---

## Understanding the Comparison

### Your Baker (Before Staking)
- Balance: 11,999 ꜩ
- **Staked: 0 ꜩ** ❌
- Attestations: 0 (17 days)

### Comparison Baker (tz3VuQRX...KMHm)
- Balance: 6,010 ꜩ
- **Staked: 6,009 ꜩ** ✅
- Attestations: 954 (4 days)

**Why?**
```
Rights = (Staked Balance / Total Network Stake) × Available Rights

Your baker:       0 / Network = 0 rights
Comparison baker: 6,009 / Network = Many rights
```

---

## What Happens When You Stake

### Before:
```
Liquid:  11,999 ꜩ  ← Can spend/transfer
Staked:  0 ꜩ       ← Frozen for baking
```

### After `npm run stake:all`:
```
Liquid:  0.5 ꜩ     ← Reserved for fees
Staked:  11,999 ꜩ  ← Frozen, earning rights
```

### After 14-21 Days:
```
You receive baking rights → Baker attests automatically → Earn rewards
```

---

## Key Concepts

**Liquid Balance:** XTZ you can spend immediately

**Staked Balance:** XTZ frozen for baking (cannot spend)

**Baking Rights:** Permission to attest blocks, assigned by protocol based on stake

**Timeline:**
- Stake → 14-21 days → Rights → Attestations → Rewards

**Unstaking:**
- Start unstake → 12 days frozen → Finalize → Funds become liquid

---

## Monitor Progress

```bash
# After staking
npm run stake:status        # Check balances
npm run baker:rights        # Check for rights (after 14+ days)

# After receiving rights
npm run baker:logs          # See live attestations
npm run monitor             # Dashboard view

# On blockchain
https://ghostnet.tzkt.io/tz1Wp2H3WFGDsKXYJWeYLmJaFeWp51fH1rWi
```

---

## Common Questions

**Q: Why 0 attestations despite having XTZ?**
A: Need to stake, not just hold XTZ.

**Q: How long until I get baking rights?**
A: 5-7 cycles ≈ 14-21 days after staking.

**Q: Can I unstake anytime?**
A: Yes, but takes 4 cycles (12 days) to unlock.

**Q: How much should I stake?**
A: On testnet, stake all (no risk). Minimum: 6,000 ꜩ.

**Q: What if I staked but still no rights after 3 weeks?**
A: Check if deactivated: `npm run delegate:status`
   If deactivated, re-register: `npm run delegate:register`

---

## Next Steps

1. **Now:** `npm run stake:all`
2. **Week 1:** Check `npm run stake:status`
3. **Week 2:** Check `npm run baker:rights`
4. **Week 3:** Should see first rights
5. **Week 4:** Watch `npm run baker:logs` for attestations

Goal: Match the comparison baker's performance (954 attestations in 4 days)
