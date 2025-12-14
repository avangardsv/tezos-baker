# Repository Structure

Current organized structure for Tezos Baker

## Root Level

### Configuration Files
```
.env.example          - Environment configuration template
config-ghostnet.json  - Ghostnet (testnet) node configuration
config-mainnet.json   - Mainnet node configuration
docker-compose.yml    - Docker services orchestration
Dockerfile            - Octez container build
```

### Documentation Files
```
README.md                      - Quick start guide
ARCHITECTURE.md               - Complete system architecture (in docs/)
AI_COMPLETE_PROMPT.md         - Comprehensive AI prompt for setup
SIMPLIFICATION_ANALYSIS.md    - Simplification options analysis
SIMPLIFICATION_STATUS.md      - Current simplification progress
```

## Directories

### `scripts/` - All Operational Scripts
**Main Scripts (simplified wrappers):**
- `setup.sh` - One-command setup (install, sync, configure)
- `start.sh` - One-command start baker (register + start)
- `status.sh` - Check sync and health status
- `stop.sh` - Stop all services

**Detailed Scripts (advanced operations):**
- `register_delegate.sh` - Register account as delegate
- `start_baker.sh` - Start baker/endorser processes
- `check_sync.sh` - Monitor node synchronization
- `backup_keys.sh` - Backup wallet keys
- `import_snapshot.sh` - Import blockchain snapshot for fast sync
- `clean_node_data.sh` - Clean node data for fresh start
- `test_logging.sh` - Test logging infrastructure
- `validate_logs.sh` - Validate log outputs

**Libraries:**
- `lib/log.sh` - Structured logging library

### `docs/` - Documentation
- `ARCHITECTURE.md` - Complete technical documentation
- `AI_PROMPTS.md` - AI integration prompts
- `SIMPLIFICATION_OPTIONS.md` - Simplification strategies
- `CONTRIBUTING.md` - Development guidelines
- `MONITORING.md` - Monitoring setup guide
- `SECURITY.md` - Security best practices
- `RUNBOOK_*.md` - Operational runbooks

### `agents/` - AI Workflow Tools (54MB - Should Move)
AI development tools and workflow automation
**Recommended**: Move to separate `tezos-baker-ai` repository

### `monitoring/` - Monitoring Stack (Optional)
- `prometheus/` - Metrics collection
- `grafana/` - Dashboards and visualization
- `alertmanager/` - Alert routing and notifications

### `security/` - Security Documentation (Optional)
- Hardening checklists
- Firewall rules
- Hardware signer guides

### `config/` - Old Config (Duplicate - Should Delete)
Duplicates of root-level config files

### `docker/` - Old Docker Files (Duplicate - Should Delete)
Duplicates of root-level Docker files

## Usage

### Quick Start (3 Commands)
```bash
./scripts/setup.sh ghostnet
docker exec tezos-node tezos-client gen keys alice
./scripts/start.sh alice ghostnet
```

### Check Status
```bash
./scripts/status.sh
```

### Stop Services
```bash
./scripts/stop.sh
```

## Simplification Progress

**Current State**: 70% simplified
- ✅ Scripts organized in `scripts/` folder
- ✅ Main configs at root level
- ✅ Documentation organized
- ⏳ Old duplicate folders still present
- ⏳ `agents/` directory (54MB) not moved yet

**Target State**: 98% simplified
- Remove `agents/` (54MB → separate repo)
- Remove `config/`, `docker/` (duplicates)
- Optional: Move `monitoring/`, `security/` to branches

**Result After Cleanup**:
- Repository size: 55MB → 1MB
- Complexity: 6/10 → 3/10
- All functionality preserved

## File Inventory

### Essential Files (Required for operation)
- 1 docker-compose.yml
- 1 Dockerfile
- 2 config files (ghostnet, mainnet)
- 4 main scripts (setup, start, status, stop)
- 9 detailed scripts (various operations)
- 1 logging library

**Total Essential**: ~250KB

### Documentation (Educational)
- Multiple markdown files: ~400KB

### Bloat (Should remove/move)
- `agents/`: 54MB
- Old duplicate folders: ~200KB

## Next Steps

1. **Immediate Use**: Run testnet with `./scripts/setup.sh ghostnet`
2. **Cleanup**: Run `./complete-simplification.sh` to remove bloat
3. **Production**: Follow ARCHITECTURE.md security sections for mainnet
