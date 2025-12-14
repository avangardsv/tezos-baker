# Documentation Index

Complete guide to all documentation in this repository.

## Quick Start

**New to Tezos Baker?** Start here:
1. Read `../README.md` (root) - Quick start in 3 commands
2. Read `STRUCTURE.md` - Understand repository organization
3. Follow setup guide in `AI_COMPLETE_PROMPT.md`

## Documentation Categories

### 🚀 Getting Started

| Document | Purpose | Audience |
|----------|---------|----------|
| `../README.md` | Quick start guide | Everyone |
| `STRUCTURE.md` | Repository organization | Everyone |
| `AI_COMPLETE_PROMPT.md` | Complete setup guide for AI | AI assistants |
| `SIMPLIFICATION_ANALYSIS.md` | Cleanup and simplification options | Maintainers |

### 🏗️ Architecture & Design

| Document | Purpose | Audience |
|----------|---------|----------|
| `ARCHITECTURE.md` | Complete system architecture (48KB) | Developers |
| `AI_PROMPTS.md` | AI integration and extension prompts | AI developers |
| `CONTRIBUTING.md` | Development guidelines | Contributors |
| `MIGRATION_COMPLETE.md` | Migration notes | Maintainers |

### 📊 Operations

| Document | Purpose | Audience |
|----------|---------|----------|
| `RUNBOOK_start_stop.md` | Service management procedures | Operators |
| `RUNBOOK_snapshot_restore.md` | Recovery procedures | Operators |
| `RUNBOOK_incidents.md` | Incident response | Operators |
| `MONITORING.md` | Monitoring setup guide | Operators |

### 🔒 Security

| Document | Purpose | Audience |
|----------|---------|----------|
| `SECURITY.md` | Security best practices | Everyone |
| `SECURITY_PRIVACY.md` | Privacy and security details | Security teams |

### 🔧 Maintenance

| Document | Purpose | Audience |
|----------|---------|----------|
| `SIMPLIFICATION_STATUS.md` | Current simplification progress | Maintainers |
| `SIMPLIFICATION_OPTIONS.md` | Cleanup strategies | Maintainers |
| `AGENTS_NOTE.md` | Notes about agents/ directory | Maintainers |

## Documentation by Use Case

### I want to: Run a testnet baker
1. `../README.md` - Quick start
2. `AI_COMPLETE_PROMPT.md` - Detailed testnet setup (Section: "Testnet Setup")

### I want to: Understand the system architecture
1. `STRUCTURE.md` - Repository organization
2. `ARCHITECTURE.md` - Complete technical documentation

### I want to: Deploy to production (mainnet)
1. `ARCHITECTURE.md` - Read "Deployment Scenarios" → "Mainnet Production"
2. `SECURITY.md` - Security best practices
3. `RUNBOOK_start_stop.md` - Operational procedures

### I want to: Monitor my baker
1. `MONITORING.md` - Monitoring setup
2. `ARCHITECTURE.md` - Read "Monitoring Layer" section
3. Enable monitoring: `docker-compose --profile monitoring up -d`

### I want to: Troubleshoot issues
1. `RUNBOOK_incidents.md` - Common incidents
2. `AI_COMPLETE_PROMPT.md` - Troubleshooting section
3. `ARCHITECTURE.md` - Component details for debugging

### I want to: Contribute or extend
1. `CONTRIBUTING.md` - Development guidelines
2. `AI_PROMPTS.md` - Extension prompts for AI
3. `ARCHITECTURE.md` - "AI Integration" section

### I want to: Simplify the repository
1. `SIMPLIFICATION_ANALYSIS.md` - Options and recommendations
2. `SIMPLIFICATION_STATUS.md` - Current progress
3. `SIMPLIFICATION_OPTIONS.md` - Detailed strategies
4. Run: `./complete-simplification.sh`

## Documentation Statistics

| Category | Files | Total Size | Status |
|----------|-------|------------|--------|
| Getting Started | 4 | ~40KB | ✅ Complete |
| Architecture | 4 | ~110KB | ✅ Complete |
| Operations | 4 | ~15KB | ✅ Complete |
| Security | 2 | ~13KB | ✅ Complete |
| Maintenance | 3 | ~32KB | ✅ Complete |
| **TOTAL** | **17** | **~210KB** | **✅ Complete** |

## File Descriptions

### ARCHITECTURE.md (48KB)
The master technical document. Contains:
- Complete system overview
- All component details
- Deployment scenarios (Ghostnet & Mainnet)
- Data flow architecture
- Network architecture
- AI integration prompts
- Comprehensive glossary

**When to read**: Understanding how everything works together

### AI_COMPLETE_PROMPT.md (21KB)
Self-contained prompt for AI assistants. Contains:
- Current repository state analysis
- Step-by-step simplification guide
- Complete testnet setup workflow
- Troubleshooting guide
- All commands with expected outputs
- Configuration explanations
- Validation checklist

**When to read**: Setting up with AI assistance or giving to less advanced AI

### SIMPLIFICATION_ANALYSIS.md (6KB)
Quick summary of cleanup options. Contains:
- Current state metrics
- 3 simplification options
- Recommendation matrix
- Quick start commands

**When to read**: Deciding how to clean up the repository

### STRUCTURE.md (4KB)
Repository organization guide. Contains:
- Directory structure
- File inventory
- Usage examples
- Simplification progress

**When to read**: Understanding where files are located

### SIMPLIFICATION_STATUS.md (9KB)
Detailed progress report. Contains:
- Current vs target metrics
- Completed tasks
- Incomplete tasks
- Completion checklist
- Migration timeline

**When to read**: Tracking cleanup progress

### SIMPLIFICATION_OPTIONS.md (17KB)
Detailed cleanup strategies. Contains:
- 5 different simplification approaches
- Comparison matrix
- Migration plans
- Pros/cons analysis

**When to read**: Planning major restructuring

## Quick Links by File Size

### Large Documents (>10KB)
- `ARCHITECTURE.md` (48KB) - Complete technical reference
- `AI_PROMPTS.md` (43KB) - AI integration guide
- `AI_COMPLETE_PROMPT.md` (21KB) - AI setup prompt
- `SIMPLIFICATION_OPTIONS.md` (17KB) - Cleanup strategies
- `SECURITY_PRIVACY.md` (11KB) - Privacy details

### Medium Documents (5-10KB)
- `SIMPLIFICATION_STATUS.md` (9KB) - Progress report
- `SIMPLIFICATION_ANALYSIS.md` (6KB) - Cleanup summary

### Small Documents (<5KB)
- `MIGRATION_COMPLETE.md` (4KB)
- `STRUCTURE.md` (4KB)
- `CONTRIBUTING.md` (1.4KB)
- `SECURITY.md` (1.1KB)
- `MONITORING.md` (763B)
- `RUNBOOK_start_stop.md` (791B)
- `AGENTS_NOTE.md` (707B)
- `RUNBOOK_incidents.md` (664B)
- `RUNBOOK_snapshot_restore.md` (566B)

## Recommended Reading Order

### For New Users (Testnet)
1. `../README.md` (5 min)
2. `AI_COMPLETE_PROMPT.md` - "Testnet Setup" section (15 min)
3. `STRUCTURE.md` (5 min)

### For Production Deployment (Mainnet)
1. `ARCHITECTURE.md` - "Deployment Scenarios" (30 min)
2. `SECURITY.md` (10 min)
3. `SECURITY_PRIVACY.md` (20 min)
4. All `RUNBOOK_*.md` files (15 min)
5. `MONITORING.md` (10 min)

### For Developers & Contributors
1. `STRUCTURE.md` (5 min)
2. `ARCHITECTURE.md` (60 min)
3. `CONTRIBUTING.md` (5 min)
4. `AI_PROMPTS.md` (30 min)

### For Repository Maintainers
1. `SIMPLIFICATION_ANALYSIS.md` (10 min)
2. `SIMPLIFICATION_STATUS.md` (15 min)
3. `SIMPLIFICATION_OPTIONS.md` (30 min)
4. `STRUCTURE.md` (5 min)

## Contributing to Documentation

See `CONTRIBUTING.md` for:
- Documentation standards
- File naming conventions
- Update procedures

## Support

- **Quick questions**: Check `../README.md`
- **Technical details**: Check `ARCHITECTURE.md`
- **Troubleshooting**: Check `AI_COMPLETE_PROMPT.md` troubleshooting section
- **Operations**: Check `RUNBOOK_*.md` files

---

**Last Updated**: 2025-12-14
**Total Documentation**: 17 files, ~210KB
**Completeness**: 100%
