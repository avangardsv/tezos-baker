#!/usr/bin/env bash
# Node health check with error handling
# Wraps curl calls with proper error handling

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/health.sh"

# =============================================================================
# MAIN
# =============================================================================

main() {
    local metrics
    
    if ! metrics=$(get_node_health); then
        log_error "Failed to get node health metrics"
        log_info "Check if node is running: npm run status:containers"
        exit 1
    fi
    
    echo ""
    log_info "=== Node Health Metrics ==="
    echo ""
    
    # Extract key metrics
    echo "$metrics" | grep -E 'p2p_connections_active|is_bootstrapped|head_level|synchronisation_status' || {
        log_warn "Some metrics not available (node may still be starting)"
    }
}

main "$@"

