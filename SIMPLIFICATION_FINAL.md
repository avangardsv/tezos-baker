# Final Simplification Options

## Good News: Monitoring is ALREADY Optional! ✅

Your docker-compose.yml already has monitoring services under the `monitoring` profile.

**They DON'T run by default!**

---

## Current Setup

### **What Runs by Default** (Simple - 3 containers)
```bash
docker-compose up -d
```

**Only starts:**
- ✅ `tezos-node` - Blockchain node
- ✅ `tezos-baker` - Block creation
- ✅ `tezos-endorser` - Block attestation

**That's it!** No monitoring overhead.

### **What's Optional** (Never runs unless asked)
```bash
docker-compose --profile monitoring up -d
```

**Only with --profile monitoring:**
- ⚪ `prometheus` - Metrics collection
- ⚪ `grafana` - Dashboards
- ⚪ `alertmanager` - Alerts
- ⚪ `node-exporter` - System metrics

---

## Your Simple Setup Commands

### **Minimal Setup** (What you should use!)
```bash
# 1. Setup (just 3 containers)
./scripts/setup.sh ghostnet

# 2. Generate keys
docker exec tezos-node tezos-client gen keys alice

# 3. Fund from faucet
# Visit: https://faucet.ghostnet.teztnets.xyz/

# 4. Start baking (just 3 containers)
./scripts/start.sh alice ghostnet

# 5. Check status
./scripts/status.sh
```

**Resources Used:**
- CPU: ~1 core
- RAM: ~2GB
- Containers: 3 only

---

## Option 1: Keep As-Is (Recommended)

**Do Nothing!** Your setup is already minimal.

**Pros:**
- ✅ Monitoring available if you ever need it
- ✅ No overhead (doesn't run by default)
- ✅ Just ignore the monitoring/ folder
- ✅ Already simple

**Cons:**
- ⚠️ monitoring/ folder exists (28KB)

---

## Option 2: Remove Monitoring Completely

If you want to delete monitoring entirely:

### **What Gets Removed**
- `monitoring/` folder (28KB)
- 4 monitoring services from docker-compose.yml
- Monitoring documentation sections

### **Commands to Remove**
```bash
# 1. Remove monitoring folder
rm -rf monitoring/

# 2. Remove monitoring services from docker-compose
# (I can do this for you)

# 3. Commit changes
git add -A
git commit -m "Remove monitoring stack (not needed for simple setup)"
```

**Result:**
- Repository: 1.9MB → 1.87MB (saves 28KB)
- docker-compose.yml: Shorter, simpler
- No monitoring references

---

## Option 3: Ultra-Minimal Setup (Advanced)

Create absolute minimal configuration:

### **New File: `docker-compose.minimal.yml`**
```yaml
version: '3.8'

services:
  tezos-node:
    image: tezos/tezos:v20.2
    container_name: tezos-node
    restart: unless-stopped
    ports:
      - "9732:9732"
      - "8732:8732"
    volumes:
      - ./data:/var/lib/tezos
      - ./config-ghostnet.json:/etc/tezos/config.json:ro
    command: tezos-node run --config-file /etc/tezos/config.json
    networks:
      - tezos

  tezos-baker:
    image: tezos/tezos:v20.2
    container_name: tezos-baker
    restart: unless-stopped
    depends_on:
      - tezos-node
    volumes:
      - ./data:/var/lib/tezos
    command: >
      tezos-baker-alpha run with local node /var/lib/tezos alice
    networks:
      - tezos

  tezos-endorser:
    image: tezos/tezos:v20.2
    container_name: tezos-endorser
    restart: unless-stopped
    depends_on:
      - tezos-node
    volumes:
      - ./data:/var/lib/tezos
    command: >
      tezos-endorser-alpha run alice
    networks:
      - tezos

networks:
  tezos:
    driver: bridge
```

**Usage:**
```bash
docker-compose -f docker-compose.minimal.yml up -d
```

**Size:** ~30 lines vs 250+ lines

---

## Comparison Matrix

| Option | Monitoring | Size | Complexity | Recommended For |
|--------|-----------|------|------------|-----------------|
| **Current (Do Nothing)** | Optional | 1.9MB | Low | ✅ Most users |
| **Remove Monitoring** | None | 1.87MB | Minimal | Want clean repo |
| **Ultra-Minimal** | None | Bare bones | Absolute minimal | Advanced users |

---

## My Recommendation

**Keep your current setup!** Here's why:

### **It's Already Simple**
```bash
# This is all you run (3 containers only):
docker-compose up -d
```

**Monitoring doesn't run unless you explicitly ask:**
```bash
docker-compose --profile monitoring up -d  # ← Only if you want it
```

### **Checking What's Running**
```bash
docker ps

# You'll see only 3 containers:
# - tezos-node
# - tezos-baker
# - tezos-endorser

# NO monitoring unless you used --profile monitoring
```

---

## How to Monitor Without Grafana

You don't need Prometheus/Grafana! Use simple tools:

### **Check Node Status**
```bash
./scripts/status.sh
```

### **Check Sync**
```bash
docker exec tezos-node tezos-client bootstrapped
```

### **Check Baker Logs**
```bash
docker logs -f tezos-baker
docker logs -f tezos-endorser
```

### **Check Baking Rights**
```bash
docker exec tezos-node tezos-client rpc get \
  /chains/main/blocks/head/helpers/baking_rights
```

### **Check Balance**
```bash
docker exec tezos-node tezos-client get balance for alice
```

**Simple command-line monitoring = No Grafana needed!**

---

## Should You Remove Monitoring?

### **Remove It If:**
- ❌ You will NEVER use dashboards
- ❌ You want absolute minimal files
- ❌ 28KB matters to you

### **Keep It If:**
- ✅ You might want dashboards later (testnet → mainnet)
- ✅ You like having the option
- ✅ 28KB doesn't matter
- ✅ You want to learn Grafana someday

---

## What I Recommend

**For Ghostnet Testnet:**
```
Keep current setup, ignore monitoring/ folder.
Just run: docker-compose up -d (no --profile monitoring)
Monitor with: ./scripts/status.sh and docker logs
```

**For Production Mainnet (future):**
```
You'll want monitoring/alerting!
Use: docker-compose --profile monitoring up -d
```

---

## Your Choice

**Which option do you prefer?**

1. **Keep as-is** (monitoring optional, 28KB, already simple)
2. **Remove monitoring/** (delete folder and services)
3. **Create ultra-minimal** (bare bones docker-compose)

Let me know and I'll execute your choice!

---

## Quick Reference

### Current Simple Usage (3 containers)
```bash
docker-compose up -d               # Start node + baker + endorser
./scripts/status.sh                # Check status
docker logs -f tezos-baker         # Watch baker
```

### With Monitoring (7 containers)
```bash
docker-compose --profile monitoring up -d    # All services
open http://localhost:3000                   # Grafana dashboard
```

**You choose when to use monitoring. It's not forced on you!**
