#!/usr/bin/env bash
# Node status check script
# Checks if node is running, bootstrapped, and synced

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
    log_info "=== Node Status Check ==="
    echo ""
    
    # Check container
    local container_name="${CONTAINER_PREFIX:-tezos}-node"
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_error "Node container '$container_name' does not exist."
        log_info "Run 'npm run node:start' first."
        exit 1
    fi
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_error "Node container '$container_name' is not running."
        log_info "Run 'npm run node:start' or 'npm run node:restart'."
        exit 1
    fi
    
    log_success "Container: Running"
    
    # Check RPC
    if ! check_rpc_endpoint; then
        exit 1
    fi
    
    log_success "RPC: Responding"
    
    # Check bootstrap status
    if is_node_bootstrapped; then
        log_success "Bootstrap: Complete"
    else
        log_warn "Bootstrap: In progress"
    fi
    
    # Get sync status
    echo ""
    log_info "=== Sync Status ==="
    
    local header
    if header=$(get_node_sync_status); then
        local level=$(echo "$header" | jq -r '.level // 0' 2>/dev/null || echo "0")
        local timestamp=$(echo "$header" | jq -r '.timestamp // ""' 2>/dev/null || echo "")
        
        if [ -n "$timestamp" ] && [ "$timestamp" != "null" ]; then
            log_info "Current level: $level"
            log_info "Block timestamp: $timestamp"
            
            # Compare with network head
            local network_header
            if network_header=$(get_network_head); then
                local network_level=$(echo "$network_header" | jq -r '.level // 0' 2>/dev/null || echo "0")
                local network_timestamp=$(echo "$network_header" | jq -r '.timestamp // ""' 2>/dev/null || echo "")
                
                if [ "$network_level" -gt 0 ]; then
                    local lag=$((network_level - level))
                    echo ""
                    log_info "Network level: $network_level"
                    if [ "$lag" -eq 0 ]; then
                        log_success "Sync: Up to date"
                    elif [ "$lag" -lt 10 ]; then
                        log_warn "Sync: $lag blocks behind"
                    else
                        log_warn "Sync: $lag blocks behind (still syncing)"
                    fi
                fi
            fi
        fi
    else
        log_error "Failed to get sync status"
    fi
    
    # Get health metrics
    echo ""
    log_info "=== Health Metrics ==="
    
    local metrics
    if metrics=$(get_node_health); then
        local connections=$(echo "$metrics" | grep -E '^octez_p2p_connections_active' | awk '{print $2}' || echo "0")
        local bootstrapped=$(echo "$metrics" | grep -E '^octez_node_is_bootstrapped' | awk '{print $2}' || echo "0")
        
        if [ "$connections" != "0" ]; then
            log_info "Active peers: $connections"
        fi
        
        if [ "$bootstrapped" = "1" ]; then
            log_success "Bootstrapped: Yes"
        else
            log_warn "Bootstrapped: No (still syncing)"
        fi
    else
        log_warn "Metrics unavailable (node may still be starting)"
    fi
    
    echo ""
    log_info "=== Summary ==="
    
    if is_node_bootstrapped; then
        log_success "✅ Node is ready for operations"
        exit 0
    else
        log_warn "⚠️  Node is still syncing - wait before running operations"
        exit 1
    fi
}

main "$@"

