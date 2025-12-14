# Tezos Baker

Run a Tezos validator in 3 commands.

## Quick Start (Ghostnet)

```bash
# 1. Setup
./scripts/setup.sh ghostnet

# 2. Start baking
./scripts/start.sh alice

# 3. Check status
./scripts/status.sh
```

## Structure

### Scripts (`scripts/`)
- `setup.sh` - Install and sync node
- `start.sh` - Register and start baking
- `stop.sh` - Stop all services
- `status.sh` - Check health
- `register_delegate.sh` - Register as delegate
- `start_baker.sh` - Start baker/endorser
- `check_sync.sh` - Check node sync
- `backup_keys.sh` - Backup wallet keys
- `import_snapshot.sh` - Import blockchain snapshot
- `clean_node_data.sh` - Clean node data

### Configuration
- `docker-compose.yml` - Service definitions
- `Dockerfile` - Octez build
- `config-ghostnet.json` - Testnet settings
- `config-mainnet.json` - Production settings
- `.env.example` - Configuration template

### Documentation (`docs/`)
- `ARCHITECTURE.md` - Complete system documentation
- `STRUCTURE.md` - Repository organization guide
- `AI_COMPLETE_PROMPT.md` - Comprehensive AI setup prompt
- `SIMPLIFICATION_ANALYSIS.md` - Simplification options
- `AI_PROMPTS.md` - AI integration prompts
- `CONTRIBUTING.md` - Development guidelines
- `MONITORING.md` - Monitoring setup
- `SECURITY.md` - Security best practices
- `RUNBOOK_*.md` - Operational runbooks

## Documentation

Everything you need is in `docs/ARCHITECTURE.md`:
- System overview
- Component details
- Deployment guides
- AI prompts for extensions
- Troubleshooting

## Advanced

For monitoring, custom validators, and HA setup:
- See `docs/ARCHITECTURE.md` "AI Integration" section
- See `docs/AI_COMPLETE_PROMPT.md` for complete AI setup guide
- See `docs/SIMPLIFICATION_ANALYSIS.md` for cleanup options

## Network Support

- **Ghostnet** (Testnet): Optimized for testing - simple and secure enough
- **Mainnet**: Not recommended with this simplified setup (needs hardware wallet, monitoring, security hardening)

**This repository is designed for Ghostnet testnet only.**

## Prerequisites

- Docker and Docker Compose
- 2+ CPU cores, 4GB RAM, 50GB+ disk (Ghostnet)

## Notes

This is a **testnet-only** setup optimized for simplicity:
- No hardware wallet required (keys stored in container)
- No advanced monitoring (use simple `docker logs` and `./scripts/status.sh`)
- Perfect for learning and testing on Ghostnet

For production mainnet deployment, see archived branches with security hardening and monitoring.
