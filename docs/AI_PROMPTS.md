# AI Prompts for Tezos Baker Implementation

## Overview

This document provides comprehensive prompts for less advanced AI systems to implement specific components of the Tezos baker system. Each prompt is self-contained with full context, requirements, and validation criteria.

**Before using these prompts**: Read `ARCHITECTURE.md` for complete system understanding.

---

## Table of Contents

1. [Transaction Validator Implementation](#1-transaction-validator-implementation)
2. [Monitoring Dashboard Enhancement](#2-monitoring-dashboard-enhancement)
3. [Automated Backup System](#3-automated-backup-system)
4. [Infrastructure Deployment](#4-infrastructure-deployment)
5. [Custom Alert Rules](#5-custom-alert-rules)
6. [Performance Optimization](#6-performance-optimization)
7. [Disaster Recovery Procedures](#7-disaster-recovery-procedures)
8. [Multi-Node High Availability](#8-multi-node-high-availability)

---

## 1. Transaction Validator Implementation

### Objective
Implement a custom transaction validator that filters mempool transactions before block construction.

### Context
```
Current System State:
- Tezos node: Running in Docker container (tezos-node)
- Baker: Queries mempool via RPC at http://tezos-node:8732
- Standard validation: Handled by Tezos protocol (signature, balance, gas)
- Need: Additional custom filtering logic

System Architecture:
- Language: Bash (for consistency with existing scripts)
- Integration: Called by baker before block construction
- Logging: Use existing lib/log.sh library
- Monitoring: Export metrics to Prometheus
```

### Requirements

#### Functional Requirements
1. **Fetch pending operations** from node mempool via RPC
2. **Apply filtering rules** based on configurable criteria
3. **Return filtered list** to baker for block construction
4. **Log all decisions** with structured logging
5. **Export metrics** for monitoring

#### Validation Rules to Implement
```json
{
  "rules": {
    "min_fee_mutez": 1000,
    "max_gas": 1040000,
    "max_storage_bytes": 60000,
    "allowed_operations": [
      "transaction",
      "origination",
      "delegation"
    ],
    "blocked_addresses": [],
    "priority_addresses": [],
    "custom_filters": {
      "reject_low_fee_ratio": true,
      "fee_to_gas_ratio_min": 0.1
    }
  }
}
```

### Implementation Files

#### File 1: `scripts/validator/transaction_validator.sh`
```bash
#!/usr/bin/env bash
#
# Transaction Validator for Tezos Baker
# Filters mempool transactions based on custom rules
#
# Usage: ./transaction_validator.sh [--dry-run] [--rules-file=path]

# Your implementation here should:
# 1. Source lib/log.sh for structured logging
# 2. Load rules from JSON config (use jq)
# 3. Query mempool: curl http://tezos-node:8732/chains/main/mempool/pending_operations
# 4. For each operation:
#    - Extract: hash, source, destination, fee, gas_limit, storage_limit
#    - Apply validation rules
#    - Log decision (ACCEPT/REJECT)
# 5. Output: JSON array of accepted operation hashes
# 6. Metrics: Export counts (total, accepted, rejected) to file for Prometheus

# Exit codes:
# 0 - Success
# 1 - Configuration error
# 2 - RPC error
# 3 - Validation error
```

#### File 2: `scripts/validator/rules.json`
```json
{
  "version": "1.0",
  "rules": {
    "min_fee_mutez": 1000,
    "max_gas": 1040000,
    "max_storage_bytes": 60000,
    "allowed_operations": ["transaction", "origination", "delegation", "reveal"],
    "blocked_addresses": [
      "# Add addresses to block"
    ],
    "priority_addresses": [
      "# Add addresses to prioritize"
    ],
    "fee_optimization": {
      "enabled": true,
      "min_fee_per_gas_mutez": 0.1,
      "min_fee_per_byte_mutez": 1
    },
    "gas_optimization": {
      "reject_if_gas_exceeds": 0.8,
      "# 0.8 = 80% of block gas limit"
    }
  },
  "logging": {
    "log_accepted": true,
    "log_rejected": true,
    "log_level": "INFO"
  }
}
```

#### File 3: `scripts/validator/lib/validation_log.sh`
```bash
#!/usr/bin/env bash
#
# Validation Logging Library
# Extends lib/log.sh with validator-specific logging

# Functions to implement:
# - log_operation_accepted(hash, fee, gas, reason)
# - log_operation_rejected(hash, fee, gas, reason)
# - log_validation_summary(total, accepted, rejected, duration_ms)
# - export_metrics(metrics_file, total, accepted, rejected)
```

### Integration Points

#### Integrate with Baker
Modify `scripts/start_baker.sh` to enable validation:
```bash
# Add environment variable
ENABLE_TX_VALIDATION=${ENABLE_TX_VALIDATION:-false}

# Add to baker startup
if [ "$ENABLE_TX_VALIDATION" = "true" ]; then
    log_step "VALIDATION" "INFO" "Transaction validation enabled"
    # Pre-filter operations before baker processes them
    # Implementation: Hook into baker's operation selection
fi
```

#### Prometheus Metrics Export
Create `monitoring/prometheus/rules/validator.yml`:
```yaml
groups:
  - name: transaction_validator
    interval: 30s
    rules:
      - alert: HighRejectionRate
        expr: (validator_rejected_total / validator_total) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High transaction rejection rate"

      - alert: ValidatorDown
        expr: up{job="validator"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Transaction validator is down"
```

### Testing Scenarios

#### Test 1: Accept Valid Transaction
```bash
# Setup: Create transaction with sufficient fee
# Expected: Transaction accepted and logged
# Verify: Check logs for ACCEPT entry
```

#### Test 2: Reject Low-Fee Transaction
```bash
# Setup: Create transaction with fee < min_fee_mutez
# Expected: Transaction rejected
# Verify: Check logs for REJECT with reason "insufficient_fee"
```

#### Test 3: Block Blacklisted Address
```bash
# Setup: Add address to blocked_addresses in rules.json
# Expected: All operations from address rejected
# Verify: Check logs for REJECT with reason "blocked_address"
```

#### Test 4: Dry-Run Mode
```bash
./transaction_validator.sh --dry-run
# Expected: Log all decisions but don't affect baker
# Verify: Metrics show dry_run=true
```

### Validation Criteria
- [ ] Script passes shellcheck validation
- [ ] All functions have error handling
- [ ] Logs use structured format from lib/log.sh
- [ ] Metrics exported in Prometheus format
- [ ] Dry-run mode works correctly
- [ ] Configuration validates on startup
- [ ] Performance: Processes 100 operations in <1 second
- [ ] Integration: Works with existing baker process

---

## 2. Monitoring Dashboard Enhancement

### Objective
Enhance Grafana dashboard with detailed baking performance and system health panels.

### Context
```
Current System:
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090
- Existing dashboard: monitoring/grafana/dashboards/tezos-baker.json
- Metrics available:
  * tezos-node:9095 (Octez metrics)
  * node-exporter:9100 (system metrics)
```

### Metrics Reference

#### Available Metrics (Prometheus)
```
# Node metrics (from tezos-node:9095)
octez_node_chain_level                    # Current blockchain level
octez_node_head_level                     # Node's head level
octez_node_p2p_connected_peers            # Connected peer count
octez_node_p2p_recv_bytes_total           # P2P data received
octez_node_p2p_sent_bytes_total           # P2P data sent
octez_rpc_request_duration_seconds        # RPC latency
octez_store_block_count                   # Stored blocks

# System metrics (from node-exporter:9100)
node_cpu_seconds_total                    # CPU usage
node_memory_MemAvailable_bytes            # Available memory
node_memory_MemTotal_bytes                # Total memory
node_disk_io_time_seconds_total           # Disk I/O time
node_network_receive_bytes_total          # Network RX
node_network_transmit_bytes_total         # Network TX
node_filesystem_avail_bytes               # Available disk space
```

### Panels to Implement

#### Panel 1: Baking Performance Overview
```json
{
  "title": "Baking Performance Overview",
  "type": "stat",
  "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
  "targets": [
    {
      "expr": "rate(octez_baker_blocks_baked_total[1h])",
      "legendFormat": "Blocks Baked/Hour"
    },
    {
      "expr": "rate(octez_endorser_endorsements_total[1h])",
      "legendFormat": "Endorsements/Hour"
    },
    {
      "expr": "(octez_baker_blocks_baked_total / octez_baker_rights_assigned_total) * 100",
      "legendFormat": "Success Rate %"
    }
  ],
  "options": {
    "reduceOptions": {
      "values": false,
      "fields": "",
      "calcs": ["lastNotNull"]
    },
    "orientation": "auto",
    "textMode": "auto",
    "colorMode": "value",
    "graphMode": "area",
    "justifyMode": "auto"
  },
  "fieldConfig": {
    "defaults": {
      "thresholds": {
        "mode": "absolute",
        "steps": [
          {"value": 0, "color": "red"},
          {"value": 90, "color": "yellow"},
          {"value": 95, "color": "green"}
        ]
      },
      "unit": "percent"
    }
  }
}
```

#### Panel 2: Real-Time Block Sync Status
```json
{
  "title": "Block Sync Status",
  "type": "graph",
  "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
  "targets": [
    {
      "expr": "octez_node_chain_level - octez_node_head_level",
      "legendFormat": "Head Lag (blocks)",
      "refId": "A"
    },
    {
      "expr": "rate(octez_node_head_level[5m]) * 60",
      "legendFormat": "Sync Speed (blocks/min)",
      "refId": "B"
    }
  ],
  "alert": {
    "conditions": [
      {
        "evaluator": {"params": [5], "type": "gt"},
        "operator": {"type": "and"},
        "query": {"params": ["A", "5m", "now"]},
        "reducer": {"type": "avg"},
        "type": "query"
      }
    ],
    "executionErrorState": "alerting",
    "frequency": "60s",
    "handler": 1,
    "name": "High Head Lag",
    "noDataState": "no_data",
    "notifications": []
  },
  "yaxes": [
    {"format": "short", "label": "Blocks"},
    {"format": "short", "label": "Speed"}
  ],
  "xaxis": {"mode": "time"}
}
```

#### Panel 3: Rewards Tracking
```json
{
  "title": "Accumulated Rewards (XTZ)",
  "type": "graph",
  "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
  "targets": [
    {
      "expr": "octez_baker_rewards_baking_total / 1000000",
      "legendFormat": "Baking Rewards",
      "refId": "A"
    },
    {
      "expr": "octez_endorser_rewards_endorsing_total / 1000000",
      "legendFormat": "Endorsing Rewards",
      "refId": "B"
    },
    {
      "expr": "(octez_baker_rewards_baking_total + octez_endorser_rewards_endorsing_total) / 1000000",
      "legendFormat": "Total Rewards",
      "refId": "C"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "currencyUSD",
      "custom": {"lineWidth": 2, "fillOpacity": 10}
    }
  },
  "options": {
    "tooltip": {"mode": "multi"},
    "legend": {"displayMode": "list", "placement": "bottom"}
  }
}
```

#### Panel 4: System Resource Utilization
```json
{
  "title": "System Resources",
  "type": "graph",
  "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
  "targets": [
    {
      "expr": "100 - (avg(irate(node_cpu_seconds_total{mode='idle'}[5m])) * 100)",
      "legendFormat": "CPU Usage %",
      "refId": "A"
    },
    {
      "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
      "legendFormat": "Memory Usage %",
      "refId": "B"
    },
    {
      "expr": "(1 - (node_filesystem_avail_bytes{mountpoint='/'} / node_filesystem_size_bytes{mountpoint='/'})) * 100",
      "legendFormat": "Disk Usage %",
      "refId": "C"
    }
  ],
  "yaxes": [
    {
      "format": "percent",
      "max": 100,
      "min": 0,
      "label": "Usage"
    }
  ],
  "alert": {
    "conditions": [
      {
        "evaluator": {"params": [90], "type": "gt"},
        "operator": {"type": "or"},
        "query": {"params": ["A", "5m", "now"]},
        "reducer": {"type": "avg"}
      }
    ],
    "name": "High Resource Usage"
  }
}
```

#### Panel 5: P2P Network Health
```json
{
  "title": "P2P Network Health",
  "type": "graph",
  "gridPos": {"h": 8, "w": 12, "x": 0, "y": 16},
  "targets": [
    {
      "expr": "octez_node_p2p_connected_peers",
      "legendFormat": "Connected Peers",
      "refId": "A"
    },
    {
      "expr": "rate(octez_node_p2p_recv_bytes_total[5m])",
      "legendFormat": "RX Rate (bytes/s)",
      "refId": "B",
      "yAxisIndex": 1
    },
    {
      "expr": "rate(octez_node_p2p_sent_bytes_total[5m])",
      "legendFormat": "TX Rate (bytes/s)",
      "refId": "C",
      "yAxisIndex": 1
    }
  ],
  "yaxes": [
    {"format": "short", "label": "Peers"},
    {"format": "Bps", "label": "Bandwidth"}
  ]
}
```

#### Panel 6: Mempool Analysis
```json
{
  "title": "Mempool Activity",
  "type": "graph",
  "gridPos": {"h": 8, "w": 12, "x": 12, "y": 16},
  "targets": [
    {
      "expr": "octez_node_mempool_pending_operations",
      "legendFormat": "Pending Operations"
    },
    {
      "expr": "octez_node_mempool_validated_operations",
      "legendFormat": "Validated Operations"
    },
    {
      "expr": "rate(octez_node_mempool_operations_applied_total[5m])",
      "legendFormat": "Apply Rate (ops/s)"
    }
  ]
}
```

### Implementation Steps

1. **Backup existing dashboard**:
   ```bash
   cp monitoring/grafana/dashboards/tezos-baker.json \
      monitoring/grafana/dashboards/tezos-baker.json.backup
   ```

2. **Edit JSON file**:
   - Add panels to `panels` array
   - Increment `gridPos.y` for new panels to avoid overlap
   - Update dashboard version number

3. **Validate JSON**:
   ```bash
   jq empty monitoring/grafana/dashboards/tezos-baker.json
   ```

4. **Reload Grafana**:
   ```bash
   docker restart tezos-grafana
   ```

5. **Test queries in Prometheus**:
   - Open http://localhost:9090
   - Test each PromQL query
   - Verify data is present

6. **Verify in Grafana**:
   - Open http://localhost:3000
   - Navigate to dashboard
   - Check all panels load correctly
   - Test time range selection

### Validation Criteria
- [ ] JSON syntax is valid
- [ ] All PromQL queries return data
- [ ] Panels display correctly in Grafana
- [ ] Alerts trigger at configured thresholds
- [ ] Dashboard loads in <3 seconds
- [ ] Time range selection works
- [ ] Legend labels are descriptive
- [ ] Colors follow consistent theme

---

## 3. Automated Backup System

### Objective
Implement comprehensive automated backup system with encryption, retention policies, and restore functionality.

### Context
```
Current System:
- Manual backup script: scripts/backup_keys.sh
- Key location: data/node/.tezos-client/
- Identity: data/node/identity.json
- Need: Automated, scheduled, encrypted backups with retention
```

### Architecture

```
Backup System Architecture
──────────────────────────

┌─────────────────────────────────────────────┐
│          Backup Scheduler                   │
│  (systemd timer or cron)                    │
└───────────────┬─────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────┐
│     backup_automated.sh                     │
│  • Validate prerequisites                   │
│  • Create timestamped backup directory      │
│  • Copy keys, identity, config              │
│  • Compress and encrypt                     │
│  • Upload to remote (optional)              │
│  • Prune old backups                        │
│  • Export metrics                           │
└───────────────┬─────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────┐
│      Backup Storage                         │
│                                             │
│  Local: ./backups/YYYY-MM-DD_HH-MM-SS/     │
│    ├── keys.tar.gz.gpg                     │
│    ├── identity.json.gpg                   │
│    ├── config.tar.gz                       │
│    ├── logs.tar.gz                         │
│    └── manifest.json                       │
│                                             │
│  Remote: S3-compatible storage (optional)   │
└─────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────┐
│     restore_backup.sh                       │
│  • List available backups                   │
│  • Validate backup integrity                │
│  • Decrypt and extract                      │
│  • Restore to data directory                │
│  • Verify restoration                       │
└─────────────────────────────────────────────┘
```

### Implementation Files

#### File 1: `scripts/backup_automated.sh`

```bash
#!/usr/bin/env bash
#
# Automated Backup Script for Tezos Baker
# Creates encrypted backups with retention policy
#
# Usage: ./backup_automated.sh [--dry-run] [--upload]

set -euo pipefail

# Source logging library
source "$(dirname "$0")/lib/log.sh"

# Configuration
BACKUP_BASE_DIR="${BACKUP_DIR:-./backups}"
DATA_DIR="${DATA_DIR:-./data/node}"
ENCRYPTION_KEY="${GPG_KEY:-}"
RETENTION_DAILY=7
RETENTION_WEEKLY=4
RETENTION_MONTHLY=6

# S3 configuration (optional)
S3_BUCKET="${S3_BUCKET:-}"
S3_ENDPOINT="${S3_ENDPOINT:-}"
AWS_ACCESS_KEY="${AWS_ACCESS_KEY:-}"
AWS_SECRET_KEY="${AWS_SECRET_KEY:-}"

# Initialize
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="$BACKUP_BASE_DIR/$TIMESTAMP"
DRY_RUN=false
UPLOAD_TO_S3=false

log_script_start "Automated backup creation"

# Parse arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --upload)
                UPLOAD_TO_S3=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Validate prerequisites
check_prerequisites() {
    log_step "PREREQUISITES" "START" "Checking backup prerequisites"

    local required_commands=("tar" "gzip" "gpg" "jq")
    validate_prerequisites "${required_commands[@]}"

    # Check data directory exists
    if [ ! -d "$DATA_DIR" ]; then
        log_step "PREREQUISITES" "ERROR" "Data directory not found: $DATA_DIR"
        exit 1
    fi

    # Check encryption key
    if [ -z "$ENCRYPTION_KEY" ]; then
        log_step "PREREQUISITES" "WARNING" "No GPG key specified, backup will not be encrypted"
    fi

    # Check S3 configuration if upload requested
    if [ "$UPLOAD_TO_S3" = true ]; then
        if [ -z "$S3_BUCKET" ]; then
            log_step "PREREQUISITES" "ERROR" "S3_BUCKET not configured"
            exit 1
        fi

        if ! command -v aws >/dev/null 2>&1; then
            log_step "PREREQUISITES" "ERROR" "AWS CLI not installed"
            exit 1
        fi
    fi

    log_step "PREREQUISITES" "SUCCESS" "All prerequisites met"
}

# Create backup directory structure
create_backup_structure() {
    log_step "STRUCTURE" "START" "Creating backup directory structure"

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$BACKUP_DIR"/{keys,config,logs}
    fi

    log_step "STRUCTURE" "SUCCESS" "Backup directory: $BACKUP_DIR"
}

# Backup wallet keys
backup_keys() {
    log_step "KEYS" "START" "Backing up wallet keys"

    local keys_source="$DATA_DIR/.tezos-client"
    local keys_dest="$BACKUP_DIR/keys"

    if [ ! -d "$keys_source" ]; then
        log_step "KEYS" "WARNING" "Keys directory not found: $keys_source"
        return 0
    fi

    if [ "$DRY_RUN" = false ]; then
        cp -r "$keys_source"/* "$keys_dest/" 2>/dev/null || true

        # Create archive
        tar -czf "$BACKUP_DIR/keys.tar.gz" -C "$BACKUP_DIR" keys

        # Encrypt if key provided
        if [ -n "$ENCRYPTION_KEY" ]; then
            gpg --encrypt --recipient "$ENCRYPTION_KEY" \
                --output "$BACKUP_DIR/keys.tar.gz.gpg" \
                "$BACKUP_DIR/keys.tar.gz"
            rm "$BACKUP_DIR/keys.tar.gz"
            log_step "KEYS" "SUCCESS" "Keys backed up and encrypted"
        else
            log_step "KEYS" "SUCCESS" "Keys backed up (unencrypted)"
        fi

        # Remove temporary directory
        rm -rf "$keys_dest"
    fi
}

# Backup node identity
backup_identity() {
    log_step "IDENTITY" "START" "Backing up node identity"

    local identity_source="$DATA_DIR/identity.json"

    if [ ! -f "$identity_source" ]; then
        log_step "IDENTITY" "WARNING" "Identity file not found: $identity_source"
        return 0
    fi

    if [ "$DRY_RUN" = false ]; then
        if [ -n "$ENCRYPTION_KEY" ]; then
            gpg --encrypt --recipient "$ENCRYPTION_KEY" \
                --output "$BACKUP_DIR/identity.json.gpg" \
                "$identity_source"
            log_step "IDENTITY" "SUCCESS" "Identity backed up and encrypted"
        else
            cp "$identity_source" "$BACKUP_DIR/identity.json"
            log_step "IDENTITY" "SUCCESS" "Identity backed up (unencrypted)"
        fi
    fi
}

# Backup configuration files
backup_config() {
    log_step "CONFIG" "START" "Backing up configuration files"

    if [ "$DRY_RUN" = false ]; then
        # Copy .env file
        [ -f .env ] && cp .env "$BACKUP_DIR/config/"

        # Copy docker configs
        cp -r docker "$BACKUP_DIR/config/" 2>/dev/null || true
        cp -r config "$BACKUP_DIR/config/" 2>/dev/null || true

        # Create archive
        tar -czf "$BACKUP_DIR/config.tar.gz" -C "$BACKUP_DIR" config
        rm -rf "$BACKUP_DIR/config"

        log_step "CONFIG" "SUCCESS" "Configuration backed up"
    fi
}

# Backup recent logs
backup_logs() {
    log_step "LOGS" "START" "Backing up recent logs"

    local logs_dir="./logs"

    if [ ! -d "$logs_dir" ]; then
        log_step "LOGS" "INFO" "No logs directory found"
        return 0
    fi

    if [ "$DRY_RUN" = false ]; then
        # Copy last 7 days of logs
        find "$logs_dir" -type f -mtime -7 -exec cp {} "$BACKUP_DIR/logs/" \; 2>/dev/null || true

        # Create archive
        tar -czf "$BACKUP_DIR/logs.tar.gz" -C "$BACKUP_DIR" logs
        rm -rf "$BACKUP_DIR/logs"

        log_step "LOGS" "SUCCESS" "Logs backed up"
    fi
}

# Create backup manifest
create_manifest() {
    log_step "MANIFEST" "START" "Creating backup manifest"

    if [ "$DRY_RUN" = false ]; then
        local manifest="$BACKUP_DIR/manifest.json"

        cat > "$manifest" << EOF
{
  "timestamp": "$TIMESTAMP",
  "version": "1.0",
  "hostname": "$(hostname)",
  "files": {
    "keys": "$([ -f "$BACKUP_DIR/keys.tar.gz.gpg" ] && echo "keys.tar.gz.gpg" || echo "null")",
    "identity": "$([ -f "$BACKUP_DIR/identity.json.gpg" ] && echo "identity.json.gpg" || echo "null")",
    "config": "$([ -f "$BACKUP_DIR/config.tar.gz" ] && echo "config.tar.gz" || echo "null")",
    "logs": "$([ -f "$BACKUP_DIR/logs.tar.gz" ] && echo "logs.tar.gz" || echo "null")"
  },
  "encrypted": $([ -n "$ENCRYPTION_KEY" ] && echo "true" || echo "false"),
  "size_bytes": $(du -sb "$BACKUP_DIR" | cut -f1)
}
EOF

        # Create checksums
        (cd "$BACKUP_DIR" && sha256sum * > checksum.sha256 2>/dev/null || true)

        log_step "MANIFEST" "SUCCESS" "Manifest created"
    fi
}

# Upload to S3 (optional)
upload_to_s3() {
    if [ "$UPLOAD_TO_S3" = false ]; then
        return 0
    fi

    log_step "S3_UPLOAD" "START" "Uploading backup to S3"

    if [ "$DRY_RUN" = false ]; then
        local s3_path="s3://$S3_BUCKET/tezos-backups/$TIMESTAMP/"

        if aws s3 cp "$BACKUP_DIR" "$s3_path" --recursive; then
            log_step "S3_UPLOAD" "SUCCESS" "Backup uploaded to $s3_path"
        else
            log_step "S3_UPLOAD" "ERROR" "Failed to upload backup to S3"
            return 1
        fi
    fi
}

# Prune old backups based on retention policy
prune_backups() {
    log_step "PRUNE" "START" "Pruning old backups"

    if [ "$DRY_RUN" = false ]; then
        # Keep daily backups (last 7 days)
        find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -mtime +$RETENTION_DAILY \
            ! -name "$(date +%Y-%m-01)*" ! -name "$(date +%Y-%m-%d -d 'last sunday')*" \
            -exec rm -rf {} \; 2>/dev/null || true

        # Keep weekly backups (last 4 weeks)
        # Implementation: Keep backups from Sundays

        # Keep monthly backups (last 6 months)
        # Implementation: Keep backups from 1st of month

        log_step "PRUNE" "SUCCESS" "Old backups pruned"
    fi
}

# Create symbolic link to latest backup
create_latest_link() {
    log_step "LINK" "START" "Creating latest backup link"

    if [ "$DRY_RUN" = false ]; then
        ln -sfn "$BACKUP_DIR" "$BACKUP_BASE_DIR/latest"
        log_step "LINK" "SUCCESS" "Latest link created"
    fi
}

# Export metrics for Prometheus
export_metrics() {
    log_step "METRICS" "START" "Exporting backup metrics"

    if [ "$DRY_RUN" = false ]; then
        local metrics_file="/var/lib/prometheus/node-exporter/backup.prom"
        local size=$(du -sb "$BACKUP_DIR" | cut -f1)
        local timestamp=$(date +%s)

        cat > "$metrics_file" << EOF
# HELP tezos_backup_last_timestamp Unix timestamp of last backup
# TYPE tezos_backup_last_timestamp gauge
tezos_backup_last_timestamp $timestamp

# HELP tezos_backup_last_size_bytes Size of last backup in bytes
# TYPE tezos_backup_last_size_bytes gauge
tezos_backup_last_size_bytes $size

# HELP tezos_backup_status Status of last backup (1=success, 0=failure)
# TYPE tezos_backup_status gauge
tezos_backup_status 1
EOF

        log_step "METRICS" "SUCCESS" "Metrics exported"
    fi
}

# Main execution
main() {
    parse_arguments "$@"

    if [ "$DRY_RUN" = true ]; then
        log_step "DRY_RUN" "INFO" "Running in dry-run mode, no changes will be made"
    fi

    log_system_info
    check_prerequisites
    create_backup_structure
    backup_keys
    backup_identity
    backup_config
    backup_logs
    create_manifest
    upload_to_s3
    prune_backups
    create_latest_link
    export_metrics

    log_step "COMPLETE" "SUCCESS" "Backup completed: $BACKUP_DIR"
}

main "$@"
```

#### File 2: `scripts/restore_backup.sh`

```bash
#!/usr/bin/env bash
#
# Restore Backup Script for Tezos Baker
# Restores encrypted backups from backup directory
#
# Usage: ./restore_backup.sh [backup_timestamp] [--force]

set -euo pipefail

source "$(dirname "$0")/lib/log.sh"

BACKUP_BASE_DIR="${BACKUP_DIR:-./backups}"
FORCE=false

log_script_start "Backup restoration"

# Your implementation:
# 1. List available backups from $BACKUP_BASE_DIR
# 2. Validate selected backup (check manifest, checksums)
# 3. Prompt user for confirmation (unless --force)
# 4. Create backup of current state before restore
# 5. Decrypt files if encrypted
# 6. Extract archives
# 7. Copy files to data directory
# 8. Verify restoration
# 9. Log all actions
```

#### File 3: Systemd Timer Configuration

Create `/etc/systemd/system/tezos-backup.service`:
```ini
[Unit]
Description=Tezos Baker Automated Backup
After=network.target docker.service

[Service]
Type=oneshot
User=tezos
Group=tezos
WorkingDirectory=/opt/tezos-baker
ExecStart=/opt/tezos-baker/scripts/backup_automated.sh --upload
StandardOutput=journal
StandardError=journal
Environment="GPG_KEY=your-gpg-key-id"
Environment="S3_BUCKET=your-bucket-name"
```

Create `/etc/systemd/system/tezos-backup.timer`:
```ini
[Unit]
Description=Daily Tezos Baker Backup
Requires=tezos-backup.service

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable timer:
```bash
sudo systemctl daemon-reload
sudo systemctl enable tezos-backup.timer
sudo systemctl start tezos-backup.timer
```

### Testing Scenarios

#### Test 1: Full Backup Cycle
```bash
# Create backup
./scripts/backup_automated.sh

# Verify files exist
ls -la backups/latest/

# Check manifest
jq . backups/latest/manifest.json

# Verify checksums
cd backups/latest && sha256sum -c checksum.sha256
```

#### Test 2: Restore Backup
```bash
# List backups
./scripts/restore_backup.sh --list

# Restore specific backup
./scripts/restore_backup.sh 2025-09-17_02-00-00

# Verify restoration
docker exec tezos-node tezos-client list known addresses
```

#### Test 3: Encryption/Decryption
```bash
# Backup with encryption
GPG_KEY=your-key-id ./scripts/backup_automated.sh

# Verify encrypted
file backups/latest/keys.tar.gz.gpg  # Should show "GPG encrypted data"

# Restore and decrypt
./scripts/restore_backup.sh latest
```

### Validation Criteria
- [ ] Backups created with correct structure
- [ ] Encryption works with GPG
- [ ] Retention policy prunes old backups
- [ ] Restore validates integrity before applying
- [ ] S3 upload succeeds (if configured)
- [ ] Metrics exported correctly
- [ ] Systemd timer runs on schedule
- [ ] Dry-run mode doesn't modify files

---

## 4. Infrastructure Deployment

### Objective
Deploy complete Tezos baker infrastructure from scratch on a fresh Ubuntu server.

### Prerequisites
- Ubuntu 22.04 LTS server
- Non-root user with sudo privileges
- Public IP address
- 100GB+ storage (Ghostnet: 50GB, Mainnet: 100GB+)
- 4GB+ RAM (8GB recommended for Mainnet)

### Deployment Checklist

Use this as a comprehensive prompt for setting up infrastructure:

```
I need to deploy a Tezos baker infrastructure on a fresh Ubuntu 22.04 server.

Current State:
- Fresh Ubuntu 22.04 LTS installation
- User: ubuntu (non-root with sudo)
- Network: Public internet access
- Storage: 100GB SSD

Target State:
- Full Tezos node synced and running
- Baker and endorser processes operational
- Monitoring stack (Prometheus, Grafana) configured
- Security hardened for production
- Automated backups enabled

Project Repository:
https://github.com/[your-repo]/tezos-baker

Please provide step-by-step commands to:

1. SYSTEM PREPARATION
   - Update system packages
   - Install required dependencies
   - Configure firewall (UFW)
   - Set up Docker and Docker Compose
   - Create necessary directories

2. SECURITY HARDENING
   - Configure SSH (disable password auth, change port)
   - Set up fail2ban
   - Enable automatic security updates
   - Configure system auditing

3. REPOSITORY SETUP
   - Clone repository
   - Configure environment variables (.env)
   - Validate Docker Compose configurations

4. SERVICE DEPLOYMENT
   - Start Docker services
   - Import blockchain snapshot (for faster sync)
   - Monitor sync progress
   - Verify services health

5. WALLET AND KEYS
   - Generate baker keys
   - Backup keys securely
   - Fund account (testnet faucet or mainnet transfer)
   - Verify balance

6. DELEGATE REGISTRATION
   - Register account as delegate
   - Check registration status
   - Monitor baking/endorsing rights allocation

7. START BAKING
   - Launch baker and endorser processes
   - Verify processes running
   - Monitor logs for errors

8. MONITORING SETUP
   - Access Grafana dashboard
   - Configure alert notifications
   - Test alert triggers
   - Set up external monitoring (optional)

9. OPERATIONAL VALIDATION
   - Run backup procedures
   - Test restore procedures
   - Practice incident runbooks
   - Verify 48+ hours stable operation

10. MAINTENANCE SETUP
    - Configure automated backups
    - Set up log rotation
    - Schedule system updates
    - Document custom configurations

For each step, provide:
- Exact commands to run
- Expected output
- Validation checks
- Troubleshooting tips if errors occur

Network: Start with Ghostnet for testing
Timeline: Allow 3-4 hours for full deployment and sync
Security: Follow production-grade security practices even for testnet
```

### Detailed Implementation Guide

See section "Component 4: Infrastructure Setup from Scratch" in `ARCHITECTURE.md` for complete step-by-step instructions.

---

## 5. Custom Alert Rules

### Objective
Implement comprehensive alert rules for Tezos baker monitoring.

### Context
```
Alerting Stack:
- Prometheus: Evaluates alert rules
- Alertmanager: Routes and sends notifications
- Configuration: monitoring/prometheus/rules/
- Notification: Email, Slack, PagerDuty (configurable)
```

### Alert Rule Categories

#### Category 1: Critical Alerts (Immediate Action Required)

**File**: `monitoring/prometheus/rules/critical.yml`
```yaml
groups:
  - name: tezos_critical
    interval: 30s
    rules:
      - alert: NodeDown
        expr: up{job="tezos-node"} == 0
        for: 2m
        labels:
          severity: critical
          component: node
        annotations:
          summary: "Tezos node is down"
          description: "Tezos node has been down for more than 2 minutes"

      - alert: BakerProcessDown
        expr: up{job="tezos-baker"} == 0
        for: 1m
        labels:
          severity: critical
          component: baker
        annotations:
          summary: "Baker process is down"
          description: "Baker process has stopped. Baking rights may be missed."

      - alert: EndorserProcessDown
        expr: up{job="tezos-endorser"} == 0
        for: 1m
        labels:
          severity: critical
          component: endorser
        annotations:
          summary: "Endorser process is down"
          description: "Endorser process has stopped. Endorsing rights may be missed."

      - alert: NodeOutOfSync
        expr: (octez_node_chain_level - octez_node_head_level) > 10
        for: 5m
        labels:
          severity: critical
          component: node
        annotations:
          summary: "Node severely out of sync"
          description: "Node is {{ $value }} blocks behind the network"

      - alert: NoPeersConnected
        expr: octez_node_p2p_connected_peers < 1
        for: 5m
        labels:
          severity: critical
          component: network
        annotations:
          summary: "No P2P peers connected"
          description: "Node has no peer connections for 5+ minutes"

      - alert: DiskSpaceCritical
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.1
        for: 5m
        labels:
          severity: critical
          component: system
        annotations:
          summary: "Disk space critically low"
          description: "Less than 10% disk space remaining"
```

#### Category 2: Warning Alerts (Monitor Closely)

**File**: `monitoring/prometheus/rules/warnings.yml`
```yaml
groups:
  - name: tezos_warnings
    interval: 60s
    rules:
      - alert: HighHeadLag
        expr: (octez_node_chain_level - octez_node_head_level) > 5
        for: 10m
        labels:
          severity: warning
          component: node
        annotations:
          summary: "Node head lag increasing"
          description: "Node is {{ $value }} blocks behind (threshold: 5)"

      - alert: LowPeerCount
        expr: octez_node_p2p_connected_peers < 10
        for: 15m
        labels:
          severity: warning
          component: network
        annotations:
          summary: "Low peer count"
          description: "Connected to {{ $value }} peers (recommended: 10+)"

      - alert: HighCPUUsage
        expr: 100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
          component: system
        annotations:
          summary: "High CPU usage"
          description: "CPU usage is {{ $value }}%"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 10m
        labels:
          severity: warning
          component: system
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value }}%"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.2
        for: 30m
        labels:
          severity: warning
          component: system
        annotations:
          summary: "Disk space running low"
          description: "Less than 20% disk space remaining"

      - alert: MissedBakingRights
        expr: (octez_baker_rights_assigned_total - octez_baker_blocks_baked_total) > 3
        for: 1h
        labels:
          severity: warning
          component: baker
        annotations:
          summary: "Missed baking opportunities"
          description: "Missed {{ $value }} baking rights in the last hour"
```

#### Category 3: Performance Alerts

**File**: `monitoring/prometheus/rules/performance.yml`
```yaml
groups:
  - name: tezos_performance
    interval: 120s
    rules:
      - alert: SlowBlockSync
        expr: rate(octez_node_head_level[5m]) < 0.5
        for: 15m
        labels:
          severity: warning
          component: node
        annotations:
          summary: "Slow block synchronization"
          description: "Syncing at {{ $value }} blocks/minute (expected: ~2)"

      - alert: HighRPCLatency
        expr: histogram_quantile(0.95, rate(octez_rpc_request_duration_seconds_bucket[5m])) > 1.0
        for: 10m
        labels:
          severity: warning
          component: node
        annotations:
          summary: "High RPC latency"
          description: "95th percentile RPC latency is {{ $value }}s"

      - alert: LargeMempool
        expr: octez_node_mempool_pending_operations > 10000
        for: 30m
        labels:
          severity: info
          component: node
        annotations:
          summary: "Large mempool size"
          description: "Mempool has {{ $value }} pending operations"
```

### Alertmanager Configuration

**File**: `monitoring/alertmanager/alertmanager.yml`
```yaml
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@yourdomain.com'
  smtp_auth_username: 'alerts@yourdomain.com'
  smtp_auth_password: 'your-app-password'
  smtp_require_tls: true

# Routing tree
route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default'

  routes:
    # Critical alerts: immediate notification
    - match:
        severity: critical
      receiver: 'critical'
      repeat_interval: 1h
      continue: true

    # Warning alerts: normal notification
    - match:
        severity: warning
      receiver: 'warning'
      repeat_interval: 4h

    # Info alerts: email only
    - match:
        severity: info
      receiver: 'info'
      repeat_interval: 24h

# Alert receivers
receivers:
  - name: 'default'
    email_configs:
      - to: 'admin@yourdomain.com'
        headers:
          Subject: '[Tezos Baker] {{ .GroupLabels.alertname }}'

  - name: 'critical'
    email_configs:
      - to: 'oncall@yourdomain.com'
        headers:
          Subject: '[CRITICAL] Tezos Baker Alert'
    webhook_configs:
      - url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        send_resolved: true
    # Uncomment for PagerDuty integration
    # pagerduty_configs:
    #   - service_key: 'your-pagerduty-service-key'

  - name: 'warning'
    email_configs:
      - to: 'admin@yourdomain.com'
        headers:
          Subject: '[Warning] Tezos Baker Alert'

  - name: 'info'
    email_configs:
      - to: 'logs@yourdomain.com'

# Inhibition rules (suppress alerts)
inhibit_rules:
  # If node is down, don't alert on baker/endorser
  - source_match:
      alertname: 'NodeDown'
    target_match:
      component: 'baker'
    equal: ['instance']

  - source_match:
      alertname: 'NodeDown'
    target_match:
      component: 'endorser'
    equal: ['instance']
```

### Testing Alert Rules

```bash
# Validate Prometheus config
docker exec tezos-prometheus promtool check config /etc/prometheus/prometheus.yml

# Validate alert rules
docker exec tezos-prometheus promtool check rules /etc/prometheus/rules/*.yml

# Validate Alertmanager config
docker exec tezos-alertmanager amtool check-config /etc/alertmanager/alertmanager.yml

# Reload configurations
docker exec tezos-prometheus killall -HUP prometheus
docker exec tezos-alertmanager killall -HUP alertmanager

# Test alert by stopping service
docker stop tezos-baker
# Wait 1-2 minutes, check Alertmanager UI: http://localhost:9093

# Check alert status in Prometheus
# Open http://localhost:9090/alerts
```

### Validation Criteria
- [ ] All YAML files valid syntax
- [ ] Alert rules compile without errors
- [ ] Test alerts trigger correctly
- [ ] Notifications sent to correct receivers
- [ ] Inhibition rules work as expected
- [ ] Alert resolution messages sent
- [ ] PagerDuty integration works (if configured)

---

## Prompt Usage Guidelines

### For Less Advanced AI Systems

When using these prompts:

1. **Provide Full Context**: Copy the entire prompt including context section
2. **Specify Environment**: Mention your OS, versions, network (Ghostnet/Mainnet)
3. **Ask for Explanations**: Request explanations for commands if unclear
4. **Request Validation**: Ask AI to provide validation steps after implementation
5. **Iterate**: If output isn't clear, ask for clarification or examples
6. **Test in Stages**: Implement and test each component before moving to next

### Example Usage

**Good Prompt**:
```
Using the "Transaction Validator Implementation" prompt from AI_PROMPTS.md,
implement a transaction validator for my Tezos baker.

Environment:
- Ubuntu 22.04
- Docker Compose setup from repository
- Currently running on Ghostnet
- Scripts use bash and lib/log.sh library

Please provide:
1. Complete implementation of scripts/validator/transaction_validator.sh
2. Example rules.json configuration
3. Integration steps with existing baker
4. Test cases to validate functionality

After implementation, show me how to:
- Test with dry-run mode
- Integrate with monitoring
- Troubleshoot common issues
```

**Bad Prompt** (too vague):
```
Help me validate transactions
```

### Troubleshooting

If AI-generated code doesn't work:

1. **Check Syntax**: Use `shellcheck` for bash scripts
2. **Verify Paths**: Ensure file paths match your environment
3. **Test Components**: Test each function independently
4. **Review Logs**: Check structured logs for errors
5. **Ask for Fixes**: Provide error messages to AI for debugging

---

## Additional Resources

- Main Architecture: `ARCHITECTURE.md`
- Operational Guide: `docs/tezos-baker/README.md`
- Security Guidelines: `security/hardening_checklist.md`
- Runbooks: `docs/tezos-baker/RUNBOOK_*.md`
- Monitoring Guide: `docs/tezos-baker/MONITORING.md`

---

## Contributing

When creating new prompts:

1. Follow the structure of existing prompts
2. Include comprehensive context section
3. Provide clear requirements and validation criteria
4. Add testing scenarios
5. Document integration points
6. Include troubleshooting tips
