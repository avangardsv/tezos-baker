#!/usr/bin/env bash
# Health check helpers with error handling
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/lib/health.sh"

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# =============================================================================
# HEALTH CHECK HELPERS
# =============================================================================

# Check if node container exists and is running
check_node_container() {
    local container_name="${CONTAINER_PREFIX:-tezos}-node"
    
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_error "Node container '$container_name' does not exist."
        log_info "Run 'npm run node:start' first."
        return 1
    fi
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_error "Node container '$container_name' is not running."
        log_info "Run 'npm run node:start' or 'npm run node:restart'."
        return 1
    fi
    
    return 0
}

# Check if baker container exists and is running
check_baker_container() {
    local container_name="${CONTAINER_PREFIX:-tezos}-baker"
    
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_error "Baker container '$container_name' does not exist."
        log_info "Run 'npm run baker:start' first."
        return 1
    fi
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_error "Baker container '$container_name' is not running."
        log_info "Run 'npm run baker:start' or 'npm run baker:restart'."
        return 1
    fi
    
    return 0
}

# Check if RPC endpoint is responding
check_rpc_endpoint() {
    local endpoint="http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}"
    local timeout="${RPC_TIMEOUT:-5}"
    
    if ! curl -s --max-time "$timeout" "$endpoint/chains/main/chain_id" >/dev/null 2>&1; then
        log_error "RPC endpoint '$endpoint' is not responding."
        log_info "Check if node is running: npm run status:containers"
        log_info "Check node logs: npm run node:logs:tail"
        return 1
    fi
    
    return 0
}

# Check if metrics endpoint is responding
check_metrics_endpoint() {
    local endpoint="http://localhost:${METRICS_PORT:-9095}/metrics"
    local timeout="${METRICS_TIMEOUT:-5}"
    
    if ! curl -s --max-time "$timeout" "$endpoint" >/dev/null 2>&1; then
        log_warn "Metrics endpoint '$endpoint' is not responding."
        log_info "Metrics may not be enabled or node is still starting."
        return 1
    fi
    
    return 0
}

# Get node health metrics with error handling
get_node_health() {
    local endpoint="http://localhost:${METRICS_PORT:-9095}/metrics"
    local timeout="${METRICS_TIMEOUT:-5}"
    local metrics
    
    if ! metrics=$(curl -s --max-time "$timeout" "$endpoint" 2>/dev/null); then
        log_error "Failed to fetch metrics from '$endpoint'"
        log_info "Node may still be starting or metrics not enabled."
        return 1
    fi
    
    if [ -z "$metrics" ]; then
        log_error "Metrics endpoint returned empty response."
        return 1
    fi
    
    echo "$metrics"
    return 0
}

# Get node sync status with error handling
get_node_sync_status() {
    local endpoint="http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}"
    local timeout="${RPC_TIMEOUT:-5}"
    local header
    
    if ! header=$(curl -s --max-time "$timeout" "$endpoint/chains/main/blocks/head/header" 2>/dev/null); then
        log_error "Failed to fetch block header from '$endpoint'"
        log_info "Node may not be running or RPC not accessible."
        return 1
    fi
    
    if [ -z "$header" ] || [ "$header" = "null" ]; then
        log_error "RPC returned empty or invalid response."
        return 1
    fi
    
    echo "$header"
    return 0
}

# Get network head for comparison (with error handling)
get_network_head() {
    local network_url="${NETWORK_RPC_URL:-https://rpc.ghostnet.teztnets.com}"
    local timeout="${NETWORK_TIMEOUT:-10}"
    local header
    
    if ! header=$(curl -s --max-time "$timeout" "$network_url/chains/main/blocks/head/header" 2>/dev/null); then
        log_warn "Failed to fetch network head from '$network_url'"
        log_info "Network comparison unavailable (may be offline)."
        return 1
    fi
    
    if [ -z "$header" ] || [ "$header" = "null" ]; then
        log_warn "Network RPC returned empty response."
        return 1
    fi
    
    echo "$header"
    return 0
}

# Check if node is bootstrapped
is_node_bootstrapped() {
    local endpoint="http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}"
    local timeout="${RPC_TIMEOUT:-5}"
    local bootstrapped
    
    if ! bootstrapped=$(curl -s --max-time "$timeout" "$endpoint/chains/main/is_bootstrapped" 2>/dev/null); then
        log_error "Failed to check bootstrap status."
        return 1
    fi
    
    if [ "$bootstrapped" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# Preflight check: Ensure node is running and bootstrapped before operations
preflight_node_check() {
    log_info "Running preflight checks..."
    
    if ! check_node_container; then
        return 1
    fi
    
    if ! check_rpc_endpoint; then
        return 1
    fi
    
    if ! is_node_bootstrapped; then
        log_error "Node is not bootstrapped yet."
        log_info "Wait for node to sync: npm run node:status"
        log_info "Check sync progress: npm run node:sync-status"
        return 1
    fi
    
    log_success "Preflight checks passed."
    return 0
}

