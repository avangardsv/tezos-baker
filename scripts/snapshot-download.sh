#!/usr/bin/env bash
# Download Tezos snapshot
# Extracted from package.json for maintainability

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# MAIN
# =============================================================================

main() {
    local snapshot_url="https://snapshots.tzinit.org/${TEZOS_NETWORK}/rolling"
    local snapshot_file="${TEZOS_NETWORK}-rolling.snapshot"
    local snapshot_path="$PROJECT_ROOT/$BACKUP_DIR/$snapshot_file"
    
    log_info "Downloading snapshot for ${TEZOS_NETWORK}..."
    log_info "URL: $snapshot_url"
    
    # Create backup directory
    mkdir -p "$PROJECT_ROOT/$BACKUP_DIR"
    
    # Check if wget is available
    if ! command -v wget >/dev/null 2>&1; then
        log_error "wget is required but not found"
        log_info "Install wget or use curl instead"
        exit 1
    fi
    
    # Download snapshot
    cd "$PROJECT_ROOT/$BACKUP_DIR"
    
    if wget -O "$snapshot_file" "$snapshot_url"; then
        log_success "Snapshot downloaded: $snapshot_path"
        log_info "File size: $(du -h "$snapshot_path" | cut -f1)"
        log_info "Import with: npm run snapshot:import"
    else
        log_error "Failed to download snapshot"
        exit 1
    fi
}

main "$@"

