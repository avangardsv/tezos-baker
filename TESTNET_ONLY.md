# Testnet-Only Simplification

**You're right!** For testnet (Ghostnet) testing, you don't need:
- ❌ Hardware wallets (Ledger)
- ❌ Advanced security
- ❌ Production monitoring

---

## What to Remove for Testnet-Only Setup

### **Option A: Just Ignore Them** (Recommended)

**Do nothing!** Just ignore these folders:
- `security/` - Only needed for mainnet production
- `monitoring/` - Only needed if you want dashboards

**They don't affect testnet usage at all.**

---

### **Option B: Delete Unnecessary Folders**

Remove everything not needed for testnet:

```bash
# Remove security guides (mainnet only)
rm -rf security/

# Remove monitoring (optional)
rm -rf monitoring/

# Result: Even simpler!
```

**What gets removed:**
- ❌ `security/` folder (28KB)
  - `remote_signer_ledger.md` - Ledger hardware wallet setup
  - `hardening_checklist.md` - OS security hardening
  - `ufw_rules.md` - Firewall configuration
- ❌ `monitoring/` folder (28KB)
  - Prometheus, Grafana, Alertmanager configs

**Total saved:** 56KB

---

## Testnet-Only Repository Structure

After removing security and monitoring:

```
tezos-baker/                        1.85MB (from 1.9MB)
│
├── README.md                       Quick start
├── config-ghostnet.json            Testnet config only
├── docker-compose.yml              Simple 3 services
├── Dockerfile                      Container build
├── .env.example                    Basic config
│
├── scripts/                        All you need
│   ├── setup.sh
│   ├── start.sh
│   ├── status.sh
│   └── stop.sh
│
└── docs/                           Documentation
    ├── INDEX.md
    ├── ARCHITECTURE.md
    └── ... (operational docs)
```

**What's left:**
- ✅ Core testnet functionality
- ✅ Simple scripts
- ✅ Documentation
- ✅ No production complexity

---

## Why Remove These?

### **security/** - Not Needed for Testnet
**Purpose:** Mainnet production security
- Hardware wallet (Ledger) setup
- OS hardening (SSH, firewall, fail2ban)
- Attack surface reduction

**Testnet:** Keys stored in container is fine (no real value)

### **monitoring/** - Not Needed for Simple Testing
**Purpose:** Production observability
- Grafana dashboards
- Prometheus metrics
- Alertmanager notifications

**Testnet:** Simple `docker logs` and `./scripts/status.sh` is enough

---

## Testnet Security (What You Actually Need)

For testnet, security is simple:

### ✅ **Good Enough:**
```bash
# Generate key
docker exec tezos-node tezos-client gen keys alice

# Keys stored in container
# Location: ./data/.tezos-client/secret_keys

# Backup (optional)
./scripts/backup_keys.sh
```

### ❌ **Not Needed:**
- Hardware wallets (Ledger)
- Remote signers
- Firewall rules
- SSH hardening
- Fail2ban
- Key encryption

**Why?** Testnet XTZ has zero value. If keys leak, just generate new ones!

---

## Simple Testnet Monitoring

For testnet, use simple commands:

### ✅ **Good Enough:**
```bash
# Check status
./scripts/status.sh

# Watch logs
docker logs -f tezos-baker
docker logs -f tezos-node

# Check sync
docker exec tezos-node tezos-client bootstrapped

# Check balance
docker exec tezos-node tezos-client get balance for alice
```

### ❌ **Not Needed:**
- Prometheus metrics
- Grafana dashboards
- Alertmanager
- Email alerts
- Slack notifications

**Why?** Testnet is for learning. Command-line is enough!

---

## Execute Cleanup

Want me to remove security/ and monitoring/ folders?

### **Commands:**
```bash
# Remove security folder
rm -rf security/

# Remove monitoring folder
rm -rf monitoring/

# Update README (remove references)
# Update docs/INDEX.md (remove security/monitoring sections)

# Commit
git add -A
git commit -m "Remove security and monitoring (testnet-only setup)"
```

---

## Comparison

### **Before (Full Setup)**
```
tezos-baker/                    1.9MB
├── scripts/
├── docs/
├── security/                   ← Mainnet only
├── monitoring/                 ← Production only
└── ...
```

### **After (Testnet-Only)**
```
tezos-baker/                    1.85MB
├── scripts/                    ← Everything you need
├── docs/                       ← Documentation
└── ...

No security/   ← Don't need Ledger for testnet
No monitoring/ ← Simple logs are enough
```

---

## Your Testnet-Only Setup

After cleanup, your simple workflow:

```bash
# 1. Setup
./scripts/setup.sh ghostnet

# 2. Generate keys (simple, no hardware wallet)
docker exec tezos-node tezos-client gen keys alice

# 3. Get testnet XTZ
# Visit: https://faucet.ghostnet.teztnets.xyz/

# 4. Start baking
./scripts/start.sh alice ghostnet

# 5. Monitor (simple)
./scripts/status.sh
docker logs -f tezos-baker
```

**3 containers. Simple logs. No complexity.**

---

## When You Need Security/Monitoring

### **Move to Mainnet (Production):**

You'll need them! But for now, on testnet:
- ✅ Simple keys in container
- ✅ Simple log monitoring
- ✅ No hardware wallet
- ✅ No advanced security

### **Later (Mainnet):**
- Restore security/ from git
- Restore monitoring/ from git
- Follow production guides
- Use hardware wallet

---

## Recommendation for Testnet

**Remove both folders:**
```bash
rm -rf security/ monitoring/
```

**You get:**
- ✅ Simpler repository (1.85MB)
- ✅ Less to read/understand
- ✅ Testnet-focused
- ✅ Still 100% functional

**Can restore later from git if needed!**

---

## Should I Remove Them?

**Yes, remove if:**
- ✅ You're ONLY testing on Ghostnet
- ✅ You won't use mainnet soon
- ✅ You want simplest possible setup
- ✅ You don't need Ledger guides

**No, keep if:**
- ⏸️ You might move to mainnet later
- ⏸️ You want to read security guides
- ⏸️ You want monitoring option
- ⏸️ 56KB doesn't matter

---

## Execute Now?

**Option 1: Remove Both** (Testnet-only)
```bash
rm -rf security/ monitoring/
# Simplest testnet setup
```

**Option 2: Remove Security Only** (Keep monitoring option)
```bash
rm -rf security/
# Keep monitoring as optional
```

**Option 3: Keep Both** (Do nothing)
```bash
# Just ignore them
# They don't run unless you use them
```

**Which option do you want?**

I recommend **Option 1** (remove both) for pure testnet simplicity.
