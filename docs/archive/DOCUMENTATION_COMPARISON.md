# Tezos Baker Implementation vs Official Documentation

**Analysis Date**: 2026-01-02
**Official Doc**: https://octez.tezos.com/docs/user/node-configuration.html
**Our Implementation**: Custom Docker-based setup with npm scripts

---

## 🔴 CRITICAL DIFFERENCES (Security/Correctness Issues)

### 1. **RPC Access Control Lists (ACLs) - MAJOR SECURITY ISSUE**

**Official Documentation Says**:
> "Exposing all RPCs over the public network is extremely dangerous and strongly advised against."

**Our Current Config** (`data/config.json`):
```json
"rpc": {
  "listen-addrs": [ "0.0.0.0:8732" ],
  "acl": [
    {
      "address": "0.0.0.0",
      "blacklist": []
    }
  ]
}
```

**Analysis**:
- ✅ Good: Listening on `0.0.0.0:8732` (accessible for baker)
- ❌ **CRITICAL**: ACL allows `0.0.0.0` with empty blacklist
- ❌ **CRITICAL**: This means **ALL RPC endpoints are exposed publicly**
- ❌ **RISK**: DoS attacks, node manipulation, security breach

**What Documentation Recommends**:
```json
"rpc": {
  "listen-addrs": [ "0.0.0.0:8732" ],
  "acl": [
    {
      "address": "127.0.0.1",
      "blacklist": []  // Full access for localhost
    },
    {
      "address": "0.0.0.0",
      "whitelist": ["GET /chains/**", "GET /monitor/**"]  // Restricted remote access
    }
  ]
}
```

**Impact**:
- Anyone can connect to your RPC endpoint
- Can submit operations, query sensitive data
- Potential for resource exhaustion attacks

**Fix Priority**: 🔴 **URGENT - Fix immediately**

---

### 2. **Configuration Management Approach**

**Official Documentation Says**:
> "Use `octez-node config update` for simple modifications, or edit `config.json` directly for advanced parameters"

**Our Implementation**:
- Uses command-line flags during `config init`:
  ```bash
  octez-node config init --network ghostnet --history-mode rolling \
    --rpc-addr 0.0.0.0:8732 --net-addr 0.0.0.0:9732
  ```
- Does NOT use `octez-node config update` for modifications
- Relies on `.env` file + bash script substitution

**Analysis**:
- ⚠️ **Issue**: Configuration changes require re-running init
- ⚠️ **Issue**: No incremental config updates
- ⚠️ **Issue**: Custom .env approach not documented by Octez team

**Official Approach**:
```bash
# Initial setup
octez-node config init

# Incremental updates
octez-node config update --rpc-addr 0.0.0.0:8732
octez-node config update --history-mode rolling
```

**Impact**:
- Harder to modify config without destroying state
- Not following standard Octez practices

**Fix Priority**: 🟡 **Medium - Refactor when convenient**

---

### 3. **Docker Implementation Not in Official Docs**

**Official Documentation**:
- Focuses on bare-metal installation
- No Docker-specific guidance in this section
- Docker verification mentioned separately (Cosign)

**Our Implementation**:
- 100% Docker-based
- Custom volume mounting (`-v "$PWD/data:/var/run/tezos/node"`)
- Custom entrypoint handling

**Analysis**:
- ✅ Docker is valid approach (Octez provides official images)
- ⚠️ Not the "default" approach in documentation
- ⚠️ No official Docker best practices guide referenced

**What's Missing**:
- Official Docker documentation exists at: `https://octez.tezos.com/introduction/howtoget.html#docker-images`
- We should follow that instead

**Fix Priority**: 🟢 **Low - Works but not aligned with docs**

---

## 🟡 MODERATE DIFFERENCES (Functionality/Best Practices)

### 4. **Data Directory Management**

**Official Documentation**:
- Default: `$HOME/.tezos-node/`
- Custom: Use `--data-dir` consistently

**Our Implementation**:
```bash
DATA_DIR=./data  # Relative path in .env
```

**Analysis**:
- ✅ Valid approach (custom data-dir)
- ⚠️ Relative path could cause issues if pwd changes
- ⚠️ Documentation implies absolute paths preferred

**Recommendation**: Use absolute paths or document pwd requirement

---

### 5. **Node Initialization Process**

**Official Documentation**:
```bash
octez-node config init
octez-node identity generate
octez-node run
```

**Our Implementation**:
```bash
npm run node:init       # config init + many flags
npm run node:identity   # identity generate
npm run node:version    # CUSTOM: writes version.json manually
npm run node:start      # run
```

**Analysis**:
- ⚠️ **Extra step**: `node:version` not in official docs
  ```bash
  echo '{"version": "3.2"}' > /var/run/tezos/node/version.json
  ```
- ⚠️ This seems like a workaround for something
- ❓ **Question**: Why is this needed? Official docs don't mention it

**Fix Priority**: 🟡 **Medium - Investigate if necessary**

---

### 6. **Monitoring Configuration**

**Official Documentation**:
- References separate monitoring docs
- Mentions OpenMetrics endpoint available
- Points to Grafana dashboards (Grafazos)

**Our Implementation**:
```env
ENABLE_METRICS=true
METRICS_PORT=9095
```

**Current Port Exposure**:
```bash
-p ${METRICS_PORT:-9095}:${METRICS_PORT:-9095}
```

**Analysis**:
- ✅ Good: Exposing metrics port
- ❌ **Missing**: No actual monitoring stack configured
- ❌ **Missing**: No Prometheus/Grafana setup
- ❌ **Gap**: We built custom health-check.sh instead of using standard tools

**What We Should Have**:
According to official ecosystem:
- Prometheus scraping port 9095
- Grafana dashboards (Grafazos project)
- AlertManager for notifications

**Fix Priority**: 🔴 **High - We built wrong solution (as discussed)**

---

### 7. **Logging Configuration**

**Official Documentation**:
```json
"log": {
  "output": "octez-node.log",
  "advertises_level": true
}
```

**Our Implementation**:
- No log configuration in `config.json`
- Relying on Docker logs (`docker logs tezos-node`)
- Custom `monitor-logs.sh` script for filtering

**Analysis**:
- ⚠️ Not using built-in Octez logging config
- ⚠️ Docker logs are not persistent (lost on container removal)
- ⚠️ No log rotation configured at Octez level

**Official Approach**:
- Configure logging in config.json
- Use Octez's built-in log management
- Reference full logging documentation

**Fix Priority**: 🟡 **Medium - Improve log persistence**

---

## 🟢 ACCEPTABLE DIFFERENCES (Valid Alternatives)

### 8. **History Mode**

**Official Documentation**:
- Supports: full, rolling, archive
- No specific recommendation

**Our Implementation**:
```env
HISTORY_MODE=rolling
```
```bash
--history-mode ${HISTORY_MODE:-rolling}
```

**Analysis**:
- ✅ Valid choice for baker setup
- ✅ Saves storage space
- ✅ Sufficient for baking operations

**Status**: ✅ **Correct - No changes needed**

---

### 9. **Network Configuration**

**Official Documentation**:
- Default port: 9732
- Default address: `[::]:9732`

**Our Implementation**:
```bash
--net-addr 0.0.0.0:9732
```

**Analysis**:
- ✅ Port 9732 matches standard
- ⚠️ Using IPv4 (`0.0.0.0`) instead of IPv6 (`[::]`)
- ✅ Works fine for most setups

**Status**: ✅ **Acceptable - IPv4 is fine**

---

### 10. **Bootstrap Peers**

**Official Documentation**:
- Auto-discovers peers from network config
- Can specify custom peers with `--peer`

**Our Implementation** (`config.json`):
```json
"bootstrap-peers": [
  "ghostnet.teztnets.com",
  "ghostnet.tzinit.org",
  "ghostnet.tzboot.net",
  "ghostnet.boot.ecadinfra.com",
  "ghostnet.stakenow.de:9733"
]
```

**Analysis**:
- ✅ Good: Explicit bootstrap peers for faster sync
- ✅ Good: Using known reliable peers
- ✅ Standard practice for production setups

**Status**: ✅ **Good practice - Keep as is**

---

## ❌ MISSING FEATURES (Not Implemented)

### 11. **ACL Customization**

**What Documentation Offers**:
- Fine-grained access control per endpoint
- Whitelist/blacklist rules
- Address-specific policies

**What We Have**:
- Basic wide-open config (security issue)

**Missing**:
- Proper ACL rules for remote access
- Endpoint-specific restrictions
- Security hardening

---

### 12. **Private Mode**

**What Documentation Offers**:
```bash
--private-mode
```
Node only connects to explicitly configured peers.

**What We Have**:
- Public mode (default)
- No private mode option in .env

**Missing**:
- Option for private baking setups
- Useful for high-security environments

---

### 13. **HTTP Caching Headers**

**What Documentation Offers**:
```bash
--enable-http-cache-headers
```
Useful behind reverse proxies like NGINX.

**What We Have**:
- No HTTP caching configured

**Missing**:
- Performance optimization for RPC queries
- CDN/cache integration capability

---

## 📊 SUMMARY SCORECARD

| Category | Status | Priority |
|----------|--------|----------|
| **Security (ACLs)** | 🔴 CRITICAL | Fix immediately |
| **Configuration Management** | 🟡 Non-standard | Refactor when convenient |
| **Docker Approach** | 🟢 Valid | Document properly |
| **Data Directory** | 🟡 Could improve | Use absolute paths |
| **Node Init Process** | 🟡 Extra steps | Investigate version.json |
| **Monitoring** | 🔴 Wrong approach | Replace with Prometheus/Grafana |
| **Logging** | 🟡 Basic | Add proper config |
| **History Mode** | ✅ Correct | No changes |
| **Network Config** | ✅ Good | No changes |
| **Bootstrap Peers** | ✅ Good practice | Keep |

---

## 🔧 REQUIRED FIXES (Priority Order)

### Priority 1: SECURITY FIX (Do Now)

**Fix ACL Configuration**:

```bash
# Stop node
npm run node:stop

# Edit data/config.json
# Replace ACL section with:
```

```json
"acl": [
  {
    "address": "127.0.0.1",
    "blacklist": []
  },
  {
    "address": "::1",
    "blacklist": []
  },
  {
    "address": "0.0.0.0",
    "whitelist": [
      "GET /chains/**",
      "GET /monitor/**",
      "GET /network/**",
      "GET /version"
    ]
  }
]
```

```bash
# Restart node
npm run node:start
```

**Verification**:
```bash
# Should work (localhost)
curl http://127.0.0.1:8732/chains/main/blocks/head

# Should work (remote, whitelisted)
curl http://YOUR_IP:8732/chains/main/blocks/head

# Should FAIL (remote, not whitelisted)
curl -X POST http://YOUR_IP:8732/injection/operation
```

---

### Priority 2: MONITORING (Replace Custom Solution)

**Remove Custom Scripts**:
- Delete: health-check.sh, monitor.sh, GitHub Actions workflow
- Keep: lib/common.sh for other scripts

**Add Standard Stack**:

1. Create `docker-compose.yml`:
```yaml
version: '3'
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana
    volumes:
      - grafana-data:/var/lib/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASS}

volumes:
  prometheus-data:
  grafana-data:
```

2. Create `prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'tezos-node'
    static_configs:
      - targets: ['host.docker.internal:9095']
    scrape_interval: 15s
```

3. Import Grafazos dashboard (official Tezos Grafana dashboards)

**Remove from cron**:
```bash
npm run health:uninstall-cron
```

---

### Priority 3: LOGGING CONFIGURATION

**Add to `data/config.json`**:
```json
"log": {
  "output": "/var/run/tezos/node/logs/octez-node.log",
  "level": "info"
}
```

**Create logs directory**:
```bash
mkdir -p data/logs
```

**Add log rotation**:
Create `logrotate.conf`:
```
/path/to/data/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
```

---

### Priority 4: CONFIGURATION MANAGEMENT

**Add config update helper**:

Create `scripts/config-update.sh`:
```bash
#!/bin/bash
source "$(dirname "$0")/lib/common.sh"

docker run --rm \
  -v "$PWD/data:/var/run/tezos/node" \
  tezos/tezos:${OCTEZ_VERSION} \
  octez-node config update "$@"
```

**Add to package.json**:
```json
"node:config": "./scripts/config-update.sh"
```

**Usage**:
```bash
npm run node:config -- --rpc-addr 0.0.0.0:8732
npm run node:config -- --history-mode full
```

---

### Priority 5: INVESTIGATE version.json

**Check why this exists**:
```bash
npm run node:version
```

**Questions**:
1. Is this needed for Docker setup?
2. Is this a workaround for bug?
3. Can we remove it?

**Action**:
- Test node startup without this step
- Check official Docker image docs
- Remove if not necessary

---

## 📚 DOCUMENTATION GAPS

### What We Need to Read

1. **Official Monitoring Docs**:
   - https://octez.tezos.com/user/node-monitoring.html
   - https://octez.tezos.com/user/openmetrics.html

2. **Official Docker Docs**:
   - https://octez.tezos.com/introduction/howtoget.html#docker-images

3. **Official Logging Docs**:
   - Referenced in node-configuration.html

4. **Official Baking Guide**:
   - https://octez.tezos.com/user/howtorun.html#baker

5. **Grafazos Project** (Official Grafana Dashboards):
   - Search for Tezos Grafana dashboards

---

## 🎯 ALIGNMENT SCORE

**Current Alignment with Official Docs**: **45/100**

**Breakdown**:
- Security: 20/40 (Major ACL issue)
- Configuration: 15/20 (Non-standard but works)
- Monitoring: 0/20 (Custom solution, not standard)
- Logging: 5/10 (Basic, no config)
- Setup Process: 5/10 (Extra steps, unclear why)

**After Fixes**: **85/100**

**What Keeps us at 85%**:
- Docker approach (not default in docs)
- npm scripts wrapper (custom convenience layer)
- Some environment variable patterns not in docs

---

## 💡 KEY LESSONS

1. **Read official docs FIRST before building**
   - We built monitoring without reading monitoring docs
   - We exposed RPC without reading security docs

2. **Use official tools, not custom scripts**
   - Prometheus/Grafana exist for monitoring
   - ACLs exist for security
   - config update exists for configuration

3. **Validate against documentation regularly**
   - Our setup drifted from standards
   - Security issues went unnoticed

4. **Question every custom script**
   - Why did we need version.json?
   - Why custom health-check instead of Prometheus?
   - Why bash scripts instead of config files?

---

## ✅ ACTION PLAN

**Immediate (Today)**:
- [ ] Fix ACL configuration (CRITICAL security issue)
- [ ] Test RPC access restrictions
- [ ] Document ACL rules

**This Week**:
- [ ] Read official monitoring documentation
- [ ] Set up Prometheus + Grafana
- [ ] Remove custom health-check solution
- [ ] Import Grafazos dashboards

**This Month**:
- [ ] Add proper logging configuration
- [ ] Implement config update workflow
- [ ] Investigate and remove version.json if unnecessary
- [ ] Review all custom scripts against official docs

**Ongoing**:
- [ ] Check official docs before building new features
- [ ] Validate configuration changes against documentation
- [ ] Prefer official tools over custom solutions
