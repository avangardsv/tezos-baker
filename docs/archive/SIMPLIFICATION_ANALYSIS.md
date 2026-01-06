# Setup Complexity Analysis & Simplification Recommendations

## Executive Summary

**Current Complexity Score: 7.5/10** (High)
**Target Complexity Score: 4/10** (Moderate)
**Potential Reduction: 47%**

This document analyzes the current Tezos baker setup against official Octez and OpenTezos documentation, identifying areas for simplification while maintaining functionality.

---

## Current Setup Analysis

### Components Inventory

| Component | Count | Complexity Impact |
|-----------|-------|-------------------|
| npm scripts | 68 | High |
| Shell scripts | 12 | Medium |
| Monitoring services | 5 | Medium |
| Documentation files | 4 | Low |
| Custom Dockerfile | 1 (unused) | Low |
| Environment variables | 15+ | Low |

**Total Complexity Score: 7.5/10**

### Official Documentation Comparison

**Octez Official Docs** (https://octez.tezos.com/docs/):
- ✅ Uses Docker (we do this)
- ✅ Uses official `tezos/tezos` images (we do this)
- ✅ Simple `docker run` commands
- ✅ Minimal configuration
- ❌ **We have:** 68 npm scripts vs. ~5-10 commands in official docs

**OpenTezos Guide** (https://opentezos.com/node-baking/deploy-a-node/installation/):
- ✅ Docker Compose for multi-container (we partially do this)
- ✅ Official images
- ✅ Simple setup flow
- ❌ **We have:** Complex npm script abstraction layer

---

## Simplification Opportunities

### 🔴 HIGH IMPACT (Reduce complexity by 30-40%)

#### 1. Consolidate npm Scripts (Priority: HIGH)

**Current:** 68 scripts
**Target:** 25-30 scripts
**Reduction:** 56-63%

**Strategy:**
- Remove redundant scripts (e.g., `node:head`, `node:chain-id` can be combined)
- Merge similar operations (e.g., `account:*` operations)
- Move advanced operations to direct Docker commands
- Keep only essential workflows

**Recommended Scripts to Keep (25):**
```json
{
  "setup": "...",
  "setup:snapshot": "...",
  "start": "...",
  "stop": "...",
  "restart": "...",
  "node:start": "...",
  "node:stop": "...",
  "node:logs": "...",
  "node:status": "...",
  "snapshot:download": "...",
  "snapshot:import": "...",
  "account:create": "...",
  "account:show": "...",
  "account:balance": "...",
  "delegate:register": "...",
  "baker:start": "...",
  "baker:stop": "...",
  "baker:logs": "...",
  "baker:status": "...",
  "stake:all": "...",
  "stake:status": "...",
  "monitoring:start": "...",
  "monitoring:stop": "...",
  "verify": "...",
  "help": "..."
}
```

**Scripts to Remove (43):**
- `node:init`, `node:identity`, `node:version` → Use `setup` only
- `node:bootstrap`, `node:head`, `node:connections`, `node:peers`, `node:chain-id` → Use `node:status` or direct commands
- `account:balance:full` → Use `account:balance` with flag
- `stake:half`, `stake:minimum`, `stake:custom` → Use `stake:all` with amount parameter
- `unstake:all`, `unstake:finalize` → Combine into `unstake`
- `monitoring:logs` → Use `docker-compose logs`
- `block:inspect` → Advanced users can use direct commands
- `security:configure-acl` → Auto-configured in `start` script
- `clean`, `clean:data`, `ps` → Use Docker commands directly

**Impact:** Reduces cognitive load, easier maintenance, aligns with official docs simplicity

---

#### 2. Simplify Shell Scripts (Priority: HIGH)

**Current:** 12 shell scripts
**Target:** 5-6 scripts
**Reduction:** 50%

**Keep:**
- `after-reboot.sh` (essential automation)
- `verify-production.sh` (production readiness)
- `help.sh` (user guidance)
- `lib/common.sh` (shared utilities)

**Remove/Consolidate:**
- `baker-status.sh` → Inline into `baker:status` npm script
- `baker-stop.sh` → Use `docker stop` directly
- `node-stop.sh` → Use `docker stop` directly
- `monitor.sh` → Use Prometheus/Grafana (already migrated)
- `configure-rpc-acl.sh` → Auto-configured in `after-reboot.sh`
- `inspect-block.sh` → Advanced users use direct commands
- `stake-funds.sh`, `stake-status.sh` → Consolidate into npm scripts

**Impact:** Reduces maintenance burden, fewer files to understand

---

#### 3. Use Docker Compose for Core Services (Priority: MEDIUM)

**Current:** Docker Compose only for monitoring
**Target:** Docker Compose for node + baker + monitoring

**Benefits:**
- Single `docker-compose up -d` command
- Automatic dependency management
- Easier restart policies
- Aligns with official OpenTezos guide

**New `docker-compose.yml` structure:**
```yaml
services:
  node:
    image: tezos/tezos:octez-v23.1
    # ... node config
  
  baker:
    image: tezos/tezos:octez-v23.1
    depends_on:
      - node
    # ... baker config
  
  prometheus:
    # ... existing monitoring config
  
  grafana:
    # ... existing monitoring config
```

**Impact:** Reduces manual container management, aligns with industry standards

---

### 🟡 MEDIUM IMPACT (Reduce complexity by 10-20%)

#### 4. Remove Unused Dockerfile (Priority: LOW)

**Current:** Custom Dockerfile exists but unused
**Action:** Delete `Dockerfile` (we use official `tezos/tezos` images)

**Impact:** Eliminates confusion, reduces maintenance

---

#### 5. Simplify Environment Variables (Priority: LOW)

**Current:** 15+ environment variables
**Target:** 8-10 essential variables

**Keep:**
- `TEZOS_NETWORK`
- `OCTEZ_VERSION`
- `HISTORY_MODE`
- `RPC_PORT`
- `P2P_PORT`
- `BAKER_ALIAS`
- `DATA_DIR`

**Remove/Default:**
- `CONTAINER_PREFIX` → Default to `tezos`
- `BACKUP_DIR` → Default to `./backups`
- `METRICS_PORT` → Default to `9095`
- `RPC_ADDR` → Default to `127.0.0.1`

**Impact:** Easier configuration, less to remember

---

#### 6. Consolidate Documentation (Priority: LOW)

**Current:** 4 documentation files
**Target:** 2 files (README.md + one reference)

**Keep:**
- `README.md` (main guide)
- `docs/MIGRATION_GUIDE.md` (reference)

**Archive/Remove:**
- Move detailed guides to `docs/archive/`
- Keep only essential information in README

**Impact:** Easier to find information

---

## Implementation Plan

### Phase 1: Script Consolidation (Week 1)

1. **Audit npm scripts** (Day 1)
   - Identify redundant scripts
   - Document usage frequency
   - Create removal plan

2. **Consolidate scripts** (Days 2-3)
   - Merge similar operations
   - Remove unused scripts
   - Update `help.sh` output

3. **Test consolidated scripts** (Day 4)
   - Verify all workflows still work
   - Update documentation

4. **Update documentation** (Day 5)
   - Simplify README
   - Update examples

**Expected Reduction:** 30-40% complexity reduction

---

### Phase 2: Docker Compose Migration (Week 2)

1. **Create unified docker-compose.yml** (Days 1-2)
   - Move node/baker to Compose
   - Keep monitoring stack
   - Test startup/shutdown

2. **Update npm scripts** (Day 3)
   - Simplify to use `docker-compose`
   - Remove manual container management

3. **Migration testing** (Day 4)
   - Test all workflows
   - Verify data persistence

4. **Documentation update** (Day 5)
   - Update README with Compose commands

**Expected Reduction:** 10-15% complexity reduction

---

### Phase 3: Cleanup (Week 3)

1. **Remove unused files** (Day 1)
   - Delete Dockerfile
   - Remove consolidated scripts
   - Clean up old documentation

2. **Simplify environment** (Day 2)
   - Reduce .env variables
   - Add defaults to scripts

3. **Final testing** (Days 3-4)
   - End-to-end workflow test
   - Verify all features work

4. **Documentation polish** (Day 5)
   - Final README review
   - Add migration notes

**Expected Reduction:** 5-10% complexity reduction

---

## Comparison: Before vs After

### Before (Current)

```
Setup Steps: 10+ commands
npm Scripts: 68
Shell Scripts: 12
Docker Commands: Manual (docker run)
Complexity: 7.5/10
```

### After (Simplified)

```
Setup Steps: 3-5 commands
npm Scripts: 25
Shell Scripts: 5
Docker Commands: docker-compose up
Complexity: 4/10
```

**Reduction: 47% complexity reduction**

---

## Alignment with Official Documentation

### Octez Documentation Alignment

| Aspect | Official Docs | Current Setup | After Simplification |
|--------|---------------|---------------|---------------------|
| Docker | ✅ Simple `docker run` | ✅ npm scripts wrapper | ✅ docker-compose |
| Images | ✅ Official `tezos/tezos` | ✅ Official images | ✅ Official images |
| Setup Steps | 3-5 commands | 10+ commands | 3-5 commands |
| Configuration | Minimal | Complex .env | Simplified .env |

### OpenTezos Guide Alignment

| Aspect | Official Guide | Current Setup | After Simplification |
|--------|----------------|---------------|---------------------|
| Docker Compose | ✅ Recommended | ⚠️ Only monitoring | ✅ Full stack |
| Scripts | Minimal | 68 npm scripts | 25 npm scripts |
| Complexity | Low | High | Moderate |

---

## Risk Assessment

### Low Risk Changes
- ✅ Removing unused Dockerfile
- ✅ Consolidating similar scripts
- ✅ Simplifying environment variables
- ✅ Consolidating documentation

### Medium Risk Changes
- ⚠️ Removing npm scripts (may break user workflows)
- ⚠️ Migrating to Docker Compose (requires testing)

### Mitigation Strategy
1. **Backward Compatibility:** Keep old scripts for 1-2 releases
2. **Migration Guide:** Document changes clearly
3. **Testing:** Comprehensive testing before removal
4. **Gradual Rollout:** Implement in phases

---

## Success Metrics

### Quantitative
- [ ] npm scripts: 68 → 25 (63% reduction)
- [ ] Shell scripts: 12 → 5 (58% reduction)
- [ ] Setup steps: 10+ → 3-5 (50% reduction)
- [ ] Complexity score: 7.5 → 4.0 (47% reduction)

### Qualitative
- [ ] Easier for new users to understand
- [ ] Aligns with official documentation
- [ ] Maintains all functionality
- [ ] Faster setup time

---

## Recommendations Summary

### Must Do (High Priority)
1. ✅ Consolidate npm scripts (68 → 25)
2. ✅ Simplify shell scripts (12 → 5)
3. ✅ Migrate to Docker Compose for core services

### Should Do (Medium Priority)
4. ✅ Remove unused Dockerfile
5. ✅ Simplify environment variables
6. ✅ Consolidate documentation

### Nice to Have (Low Priority)
7. ⚠️ Add setup wizard script
8. ⚠️ Create quick start guide
9. ⚠️ Add complexity metrics tracking

---

## Next Steps

1. **Review this analysis** with team/stakeholders
2. **Prioritize changes** based on impact vs effort
3. **Create detailed implementation plan** for Phase 1
4. **Begin Phase 1** (script consolidation)
5. **Measure results** and iterate

---

## References

- [Octez Documentation](https://octez.tezos.com/docs/)
- [OpenTezos Installation Guide](https://opentezos.com/node-baking/deploy-a-node/installation/)
- [Docker Compose Best Practices](https://docs.docker.com/compose/production/)

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-04  
**Author:** Setup Complexity Analysis

