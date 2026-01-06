# README Optimization Plan

**Purpose:** Simplify and optimize docs/README.md for study mode while maintaining essential information.

**Target Audience:** Less advanced AI assistants or developers new to the codebase.

**Current State:**
- Length: 320 lines
- Sections: 36 (too many)
- Problem: Information overload for beginners
- Goal: Reduce to ~150-200 lines, 15-20 sections maximum

---

## Phase 1: Analysis (5 minutes)

### Step 1.1: Read Current README

```bash
cat docs/README.md
```

**Take note of:**
- Which sections are essential for beginners?
- Which sections duplicate other docs?
- Which sections are too advanced for "Quick Start"?

### Step 1.2: Identify Redundancies

**Known redundancies to fix:**
1. Staking appears in 3 places (Quick Start, Critical section, Metrics)
2. Grafana info duplicated (Monitoring section + Metrics section)
3. Commands listed multiple times (Essential Commands + throughout doc)
4. Health checks scattered (Monitoring + Metrics + Health Check Summary)

---

## Phase 2: Document Purpose & Audience (3 minutes)

### Step 2.1: Define README Purpose

The README should answer ONLY these questions:
1. How do I get started in 5 minutes? (Quick Start)
2. What commands do I need to know? (Essential Commands)
3. How do I check if everything is working? (Basic Health Check)
4. Where do I go for more info? (Links to other docs)

**Out of scope for README:**
- Detailed metric explanations (belongs in MONITORING-GUIDE.md)
- Comprehensive troubleshooting (belongs in dedicated guide)
- Grafana setup details (belongs in archived docs)
- Advanced configurations (belongs in archived docs)

---

## Phase 3: Create Simplified Structure (10 minutes)

### Step 3.1: Proposed New Structure

```markdown
# Tezos Baker - Study Mode

Quick start guide for learning Tezos baking on Ghostnet testnet.

## Prerequisites
- Docker installed
- .env file configured

## Quick Start (5 Minutes)
1. Setup node
2. Create account
3. Activate baker

## Essential Commands
- Node operations (3 commands)
- Account operations (3 commands)
- Staking operations (2 commands)
- Baker operations (3 commands)
- Help (1 command)

## Health Check
- Single command to verify everything works
- What healthy output looks like

## Common Issues
- 3-5 most common problems with fixes

## Next Steps
- Link to STAKING-GUIDE.md (detailed staking)
- Link to monitoring setup (if needed)
- Link to official docs

## Resources
- Official links
- Faucet
- Explorer
```

**Total sections: ~12** (down from 36)

### Step 3.2: Content to Move Out

**Move to new file: docs/MONITORING-GUIDE.md**
- All detailed metrics explanations
- Grafana dashboard setup
- Prometheus queries
- Advanced health checks
- Metric thresholds and ranges

**Move to docs/TROUBLESHOOTING.md**
- Detailed troubleshooting steps
- Error diagnostics
- Recovery procedures
- Advanced debugging

**Keep in README:**
- Basic "is it working?" check only
- Link to full monitoring guide

---

## Phase 4: Execute Optimization (30 minutes)

### Step 4.1: Create New MONITORING-GUIDE.md

**File:** `docs/MONITORING-GUIDE.md`

**Content to extract from README:**
- "📊 Important Metrics & Health Checks" section
- "📈 Grafana Monitoring (Optional)" section
- All detailed metric explanations
- Healthy value ranges
- Dashboard links and setup

**Template:**

```markdown
# Monitoring Guide

Complete guide to monitoring your Tezos baker on Ghostnet.

## Quick Metrics Check

[Simple commands for checking status]

## Key Metrics Explained

### 1. P2P Connections
[Move from README]

### 2. Sync Status
[Move from README]

### 3. Block Level
[Move from README]

### 4. Staking Status
[Move from README]

## Grafana Setup (Optional)

[Move Grafana section from README]

## Advanced Monitoring

[Additional advanced topics]
```

**Action:**
```bash
# Create the file
touch docs/MONITORING-GUIDE.md

# Copy relevant sections from README
# (use Edit tool to extract sections)
```

### Step 4.2: Simplify README - Remove Redundancy

**In docs/README.md:**

1. **Remove duplicate staking info:**
   - Keep ONLY in "Critical: Staking Required" section
   - Remove from Quick Start (just reference it)
   - Remove from Metrics section (moved to MONITORING-GUIDE.md)

2. **Consolidate commands:**
   - Keep ONE "Essential Commands" section
   - Remove scattered command examples
   - Use simple format: command + brief description

3. **Simplify Health Check:**
   - Replace complex multi-line script with simple version
   - Keep ONLY basic check in README
   - Move comprehensive checks to MONITORING-GUIDE.md

**Example of simplified health check:**

```markdown
## Quick Health Check

Check if your baker is healthy:

```bash
# Check everything at once
curl -s http://localhost:9095/metrics | grep -E "p2p_connections_active|is_bootstrapped|head_level"
```

**Healthy output:**
- Connections: 10-30
- Bootstrapped: 1.000000 (means YES)
- Level: Should be close to latest block

**For detailed monitoring:** See [MONITORING-GUIDE.md](MONITORING-GUIDE.md)
```

### Step 4.3: Optimize Section Order

**Reorder sections for better flow:**

```markdown
1. Title + Brief description
2. Prerequisites (what you need before starting)
3. Quick Start (get running in 5 min)
4. Critical: Staking (why this matters)
5. Essential Commands (what you'll use daily)
6. Quick Health Check (is it working?)
7. Common Issues (quick troubleshooting)
8. Next Steps (where to go from here)
9. Resources (external links)
10. Simplification Notes (historical context)
```

### Step 4.4: Reduce Verbosity

**Apply these rules:**

1. **Remove filler words:**
   - Before: "This is a comprehensive guide that will help you..."
   - After: "Guide to..."

2. **Use tables instead of lists where possible:**
   - Condense 10 lines into 3-row table

3. **Remove redundant examples:**
   - Keep 1 example per concept, not 3

4. **Shorten explanations:**
   - "What they mean" sections: 2 bullets max
   - Move detailed explanations to MONITORING-GUIDE.md

5. **Remove ASCII art/decorative elements:**
   - Remove: `===`, `---`, excessive spacing
   - Keep: Emojis for section headers (visual scanning)

---

## Phase 5: Implementation Steps (45 minutes)

### Step 5.1: Create MONITORING-GUIDE.md

```bash
# 1. Create new file
touch docs/MONITORING-GUIDE.md

# 2. Copy these sections from README:
# - "📊 Important Metrics & Health Checks" (entire section)
# - "📈 Grafana Monitoring (Optional)" (entire section)
# - "🚨 Health Check Summary" (comprehensive check only)

# 3. Format as standalone guide
# - Add title: "# Monitoring Guide"
# - Add intro: "Complete guide for monitoring Tezos baker"
# - Organize into logical sections
```

### Step 5.2: Edit README - Remove Moved Content

**Use Edit tool on docs/README.md:**

1. Delete "📊 Important Metrics & Health Checks" section
2. Delete "📈 Grafana Monitoring (Optional)" section
3. Delete "🚨 Health Check Summary" section
4. Keep section headers but replace content with link to MONITORING-GUIDE.md

**Example:**

```markdown
## Monitoring & Health Checks

For detailed monitoring and metrics:
- **[Monitoring Guide](MONITORING-GUIDE.md)** - Complete metrics reference
- **[Grafana Setup](MONITORING-GUIDE.md#grafana-setup)** - Dashboard configuration

Quick health check:
```bash
curl -s http://localhost:9095/metrics | grep -E "connections_active|is_bootstrapped"
```

Expected: 10-30 connections, bootstrapped=1
```

### Step 5.3: Simplify "Quick Start" Section

**Before (verbose):**
```markdown
### Initial Setup
```bash
npm run setup                   # Initialize node + identity
npm run snapshot:download       # Download Ghostnet snapshot (recommended)
npm run snapshot:import         # Import snapshot for fast sync
npm run node:start              # Start Tezos node
```
```

**After (concise):**
```markdown
### 1. Setup Node
```bash
npm run setup                   # Initialize
npm run snapshot:download       # Get snapshot (recommended)
npm run snapshot:import         # Import for fast sync
npm run node:start              # Start node
```
```

Apply same pattern to all Quick Start sub-sections.

### Step 5.4: Consolidate "Essential Commands"

**Current:** Commands scattered + detailed explanations

**New:** Single clean reference table

```markdown
## Essential Commands

| Category | Command | Purpose |
|----------|---------|---------|
| **Setup** | `npm run setup` | Initialize node |
| | `npm run snapshot:import` | Fast sync |
| **Node** | `npm run node:start` | Start node |
| | `npm run node:stop` | Stop node |
| | `npm run node:logs` | View logs |
| **Account** | `npm run account:create` | Generate keys |
| | `npm run account:show` | Show address |
| | `npm run account:balance` | Check balance |
| **Staking** | `npm run stake:status` | Check status |
| | `npm run stake:all` | Stake funds |
| **Baker** | `npm run delegate:register` | Register delegate |
| | `npm run baker:start` | Start baker |
| | `npm run baker:logs` | View logs |
| **Help** | `npm run help` | Show all commands |

**Full workflow:** setup → snapshot → node → account → stake → delegate → baker
```

### Step 5.5: Simplify "Common Issues"

**Current:** Long explanations for each issue

**New:** Problem + Fix format

```markdown
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

**More help:** See [TROUBLESHOOTING.md](archive/TROUBLESHOOTING.md)
```

### Step 5.6: Clean Up "Resources" Section

**Current:** Multiple subsections

**New:** Single concise section

```markdown
## Resources

**Official Docs:**
[Octez](https://octez.tezos.com/docs/) • [OpenTezos](https://opentezos.com/node-baking/) • [Tezos GitLab](https://tezos.gitlab.io/)

**Ghostnet Tools:**
[Faucet](https://faucet.ghostnet.tezostaquito.io/) • [Explorer](https://ghostnet.tzkt.io/)

**Detailed Guides:**
[Staking Guide](STAKING-GUIDE.md) • [Monitoring Guide](MONITORING-GUIDE.md) • [Production Docs](archive/)
```

---

## Phase 6: Quality Check (10 minutes)

### Step 6.1: Verify Optimization Goals

**Check against targets:**

```bash
# Count lines
wc -l docs/README.md
# Target: 150-200 lines (down from 320)

# Count sections
grep "^##" docs/README.md | wc -l
# Target: 15-20 sections (down from 36)

# Count words
wc -w docs/README.md
# Target: Reduce by 40-50%
```

### Step 6.2: Test Readability

**Read through README as a beginner:**
- Can I get started in 5 minutes? ✓
- Are commands easy to find? ✓
- Do I know what to do if something breaks? ✓
- Is it overwhelming? ✗ (should be NO)

### Step 6.3: Verify Links Work

```bash
# Check all markdown links
grep -o '\[.*\](.*\.md)' docs/README.md

# Verify files exist
ls docs/STAKING-GUIDE.md
ls docs/MONITORING-GUIDE.md  # Should exist after Phase 5.1
```

### Step 6.4: Check Flow

**Optimal reading flow:**
1. Quick scan of structure (headers)
2. Read Quick Start (5 min)
3. Find essential commands (reference)
4. Check health (1 command)
5. Link out for deep dives

**Anti-patterns to avoid:**
- Scrolling past 3+ screens to find commands
- Reading explanations before seeing commands
- Mixing beginner + advanced content
- No clear "what's next" direction

---

## Phase 7: Create Archive Documentation (15 minutes)

### Step 7.1: Remove Production Pricing from Root README

**Issue:** Root README.md contains extensive mainnet pricing that's irrelevant for Ghostnet testnet.

**Found pricing sections in `/Users/admin/tezos-baker/README.md`:**

1. **Line 760:** XTZ stake value ~$22,000-30,000 USD
2. **Lines 767-770:** VPS/infrastructure costs ($20-150/month)
3. **Lines 834-850:** Complete "💰 Cost Estimate" section
   - XTZ stake: $22,000-30,000
   - Ledger Nano X: $150
   - VPS: $20-80/month
   - Expected returns: ~$90-125/month
   - Net profit calculations
4. **Line 891:** Capital requirement $22k-30k
5. **Line 914:** VPS provisioning costs

**Why this is wrong for Ghostnet:**
- Ghostnet tokens have **ZERO value** (testnet)
- All pricing is for mainnet production
- Misleading for students learning on testnet
- Creates false expectations about costs

**Action required:**

```bash
# 1. Remove entire "💰 Cost Estimate" section (lines 834-850)
# 2. Remove capital requirement mentions (line 760, 891)
# 3. Replace production sections with "Study Mode" notes
# 4. Move production info to docs/archive/PRODUCTION-GUIDE.md
```

**Replacement text for removed sections:**

```markdown
### 🎓 Study Mode (Current Setup)

**Ghostnet Testnet:**
- **Stake required:** 6,000+ ꜩ (testnet tokens, zero value)
- **Get tokens:** [Ghostnet Faucet](https://faucet.ghostnet.tezostaquito.io/)
- **Infrastructure:** Any computer (laptop OK, no 24/7 required)
- **Security:** Basic (no Ledger needed for testnet)
- **Cost:** $0 (completely free for learning)

**Purpose:** Learn Tezos baking mechanics without financial risk.

**For production/mainnet:** See [docs/archive/PRODUCTION-GUIDE.md](docs/archive/PRODUCTION-GUIDE.md)
```

**Sections to remove completely:**
- "💰 Cost Estimate" (lines 834-850)
- Production infrastructure pricing (lines 767-770)
- Expected returns calculations
- Capital requirement mentions

**Sections to modify:**
- "Minimum Stake" (line 757-760) - Keep testnet info, remove mainnet pricing
- "Infrastructure" (line 762-771) - Replace with "Study Mode" version
- "Key Risks" (line 886-892) - Remove "Capital requirement" item

### Step 7.2: Ensure Archived Docs Are Referenced

**In README, add clear archive references:**

```markdown
## Archived Documentation

Production guides moved to `docs/archive/`:
- [Security Guide](archive/SECURITY.md) - RPC hardening, firewall config
- [Production Readiness](archive/PRODUCTION_READINESS.md) - Deployment checklist
- [Monitoring Stack](archive/GRAFANA_SETUP.md) - Full Grafana/Prometheus setup

**Note:** These are for future production deployment. Not needed for Ghostnet study mode.
```

---

## Phase 8: Final Polish (10 minutes)

### Step 8.1: Apply Consistent Formatting

**Standardize command blocks:**
```markdown
# Good:
```bash
npm run command    # Brief description
```

# Bad:
```bash
# This is a long explanation of what the command does
# and why you might want to run it...
npm run command
```
```

**Standardize section headers:**
- Use title case: "Quick Start" not "Quick start"
- Use emoji only for major sections
- Keep hierarchy: # → ## → ### (no ####)

### Step 8.2: Add Version & Update Info

**At bottom of README:**
```markdown
---

**Study Mode Version:** 1.0.0
**Last Updated:** 2026-01-06
**Optimized for:** Ghostnet testnet learning
**Production docs:** See `docs/archive/`
```

### Step 8.3: Create CHANGELOG Entry

**In docs/CHANGELOG-SIMPLIFICATION.md, add:**

```markdown
## README Optimization (2026-01-06)

**Changes:**
- Reduced from 320 to ~180 lines (44% reduction)
- Consolidated 36 sections to 18 sections
- Moved detailed metrics to MONITORING-GUIDE.md
- Simplified command reference to table format
- Removed redundant staking explanations
- Created concise health check
- Improved beginner readability

**New files created:**
- docs/MONITORING-GUIDE.md - Complete metrics reference

**Impact:**
- Faster onboarding for new users
- Easier to find essential commands
- Less overwhelming for beginners
- Better separation of concerns (quick start vs deep dive)
```

---

## Phase 9: Validation (10 minutes)

### Step 9.1: Before/After Comparison

**Metrics to track:**

| Metric | Before | After | Target | Status |
|--------|--------|-------|--------|--------|
| Lines | 320 | ??? | 150-200 | ??? |
| Sections | 36 | ??? | 15-20 | ??? |
| Words | ??? | ??? | -40% | ??? |
| Commands | Scattered | Table | Organized | ??? |
| Health check | 30 lines | 5 lines | Simple | ??? |

### Step 9.2: User Journey Test

**Simulate new user experience:**

1. **First-time user arrives at README**
   - Can they start in 5 minutes? YES/NO
   - Do they know what commands to run? YES/NO
   - Can they verify it's working? YES/NO

2. **User encounters problem**
   - Can they find fix in "Common Issues"? YES/NO
   - Do they know where to get more help? YES/NO

3. **User wants to learn more**
   - Clear links to detailed guides? YES/NO
   - Guides are in logical locations? YES/NO

**Target:** All YES

### Step 9.3: Technical Validation

```bash
# Verify markdown syntax
# (if you have markdown linter)
markdownlint docs/README.md

# Verify links work
# Check all [text](file.md) references exist
for file in $(grep -o '](.*\.md)' docs/README.md | sed 's/](\(.*\))/\1/'); do
  if [ -f "docs/$file" ]; then
    echo "✓ $file"
  else
    echo "✗ $file - MISSING"
  fi
done

# Spell check (optional)
aspell check docs/README.md
```

---

## Success Criteria

**README is optimized when:**

✅ Length: 150-200 lines (down from 320)
✅ Sections: 15-20 (down from 36)
✅ Reading time: 5 minutes (down from 10+)
✅ Commands: Single organized table (not scattered)
✅ Health check: 1 simple command (not 30-line script)
✅ Staking: Explained once (not 3 times)
✅ Grafana: Linked, not detailed (moved to MONITORING-GUIDE.md)
✅ Metrics: Basic check only (details in MONITORING-GUIDE.md)
✅ Flow: Linear (setup → commands → health → resources)
✅ Links: All working, pointing to correct files
✅ New user: Can start in 5 minutes without confusion

**Bonus optimization:**
- Table of contents (for easy navigation)
- Visual hierarchy (proper header levels)
- Scannable (can find info without reading everything)

---

## Rollback Plan

If optimization makes README worse:

```bash
# Restore from git
git checkout HEAD -- docs/README.md

# Or restore from backup
cp docs/README.md.backup docs/README.md

# Keep new MONITORING-GUIDE.md
# It's still valuable even if README stays verbose
```

---

## Notes for Less Advanced AI

**When executing this plan:**

1. **Read the entire plan first** before making any changes
2. **Work in phases** - complete Phase 1 before Phase 2
3. **Create backups** before editing:
   ```bash
   cp docs/README.md docs/README.md.backup
   ```
4. **Test after each phase** - verify links work, commands are correct
5. **Use Edit tool** for modifications, not Write (safer for existing files)
6. **Commit after each phase** if using git
7. **Ask for feedback** if uncertain about content to remove

**Key principles:**
- **Simplify, don't delete critical info** - move it to other docs
- **Optimize for scanning** - tables, bullets, short paragraphs
- **Reduce cognitive load** - 1 concept per section
- **Maintain accuracy** - don't simplify to the point of incorrectness
- **Keep links working** - verify every markdown link

**Red flags (stop and ask user):**
- Removing security-critical information
- Deleting commands that users need
- Breaking links to important guides
- Making setup more complex (not simpler)
- Losing important context about staking (critical for baking!)

---

## Estimated Time

- **Total time:** ~2 hours
- **Phase 1-3 (Planning):** 20 minutes
- **Phase 4-5 (Execution):** 75 minutes
- **Phase 6-9 (Validation):** 25 minutes

**For faster execution:**
- Skip detailed validation (Phase 9)
- Use templates provided (don't write from scratch)
- Focus on core optimization (Phases 4-5)

---

## Questions to Clarify

**Before starting, confirm:**

1. ✅ Create MONITORING-GUIDE.md? (recommended: YES)
2. ✅ Target length 150-200 lines? (recommended: YES)
3. ✅ **RESOLVED:** Pricing issue identified in root README.md
   - **File:** `/Users/admin/tezos-baker/README.md` (root, not docs/)
   - **Sections:** Lines 760, 767-770, 834-850, 891, 914
   - **Action:** Remove all mainnet pricing, replace with "Study Mode" section
   - **See:** Phase 7.1 for detailed removal plan

---

**End of Optimization Plan**

**Next Step:** Execute Phase 1 or ask user for clarification on pricing issue.
