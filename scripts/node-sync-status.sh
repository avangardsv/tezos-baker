#!/usr/bin/env bash
# Node sync status comparison with error handling
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
    echo ""
    log_info "=== Your Node ==="
    
    local header
    if header=$(get_node_sync_status); then
        local level=$(echo "$header" | jq -r '.level // 0' 2>/dev/null || echo "0")
        local timestamp=$(echo "$header" | jq -r '.timestamp // ""' 2>/dev/null || echo "")
        
        if [ -n "$timestamp" ] && [ "$timestamp" != "null" ]; then
            echo "Level: $level"
            echo "Timestamp: $timestamp"
        else
            log_error "Invalid response from node"
        fi
    else
        log_error "Failed to get node status"
        log_info "Check if node is running: npm run status:containers"
        exit 1
    fi
    
    echo ""
    log_info "=== Network Head ==="
    
    local network_header
    if network_header=$(get_network_head); then
        local network_level=$(echo "$network_header" | jq -r '.level // 0' 2>/dev/null || echo "0")
        local network_timestamp=$(echo "$network_header" | jq -r '.timestamp // ""' 2>/dev/null || echo "")
        
        if [ -n "$network_timestamp" ] && [ "$network_timestamp" != "null" ]; then
            echo "Level: $network_level"
            echo "Timestamp: $network_timestamp"
            
            if [ "$level" -gt 0 ] && [ "$network_level" -gt 0 ]; then
                local lag=$((network_level - level))
                echo ""
                if [ "$lag" -eq 0 ]; then
                    log_success "✅ Node is synced (0 blocks behind)"
                elif [ "$lag" -lt 10 ]; then
                    log_warn "⚠️  Node is $lag blocks behind"
                else
                    log_warn "⚠️  Node is $lag blocks behind (still syncing)"
                fi
            fi
        else
            log_warn "Invalid response from network RPC"
        fi
    else
        log_warn "Network comparison unavailable"
    fi
}

main "$@"

