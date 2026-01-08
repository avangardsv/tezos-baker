#!/usr/bin/env bash
# Import Tezos snapshot
# Extracted from package.json for maintainability

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# MAIN
# =============================================================================

main() {
    local snapshot_file="${TEZOS_NETWORK}-rolling.snapshot"
    local snapshot_path="$PROJECT_ROOT/$BACKUP_DIR/$snapshot_file"
    
    if [ ! -f "$snapshot_path" ]; then
        log_error "Snapshot file not found: $snapshot_path"
        log_info "Download first: npm run snapshot:download"
        exit 1
    fi
    
    log_info "Importing snapshot: $snapshot_file"
    log_info "This may take several minutes..."
    
    docker run --rm \
        --entrypoint octez-node \
        -v "$PROJECT_ROOT/$DATA_DIR:/var/run/tezos/node" \
        -v "$PROJECT_ROOT/$BACKUP_DIR:/backups:ro" \
        "tezos/tezos:${OCTEZ_VERSION}" \
        snapshot import "/backups/$snapshot_file" \
        --data-dir /var/run/tezos/node
    
    log_success "Snapshot imported successfully"
    log_info "Start node with: npm run node:start"
}

main "$@"

