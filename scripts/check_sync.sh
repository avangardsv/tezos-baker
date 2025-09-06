#!/usr/bin/env bash

# Tezos Baker - Node Synchronization Check Script
# Monitors Tezos node synchronization status and head lag
#
# Usage: ./check_sync.sh [network] [max_lag]
#   network: ghostnet (default) or mainnet
#   max_lag: maximum acceptable head lag in blocks (default: 2)

set -euo pipefail

# Source logging library
source "$(dirname "$0")/lib/log.sh"

# Configuration
NETWORK="${1:-ghostnet}"
MAX_LAG="${2:-2}"
CONTAINER_NAME="tezos-node"
CHECK_INTERVAL=30
MAX_CHECKS=120  # 1 hour with 30s intervals

# Initialize script logging
log_script_start "Check $NETWORK node synchronization (max lag: $MAX_LAG)"

# Validate parameters
validate_parameters() {
    log_step "VALIDATION" "START" "Validating input parameters"
    
    case "$NETWORK" in
        "ghostnet"|"mainnet")
            log_step "VALIDATION" "SUCCESS" "Network '$NETWORK' is valid"
            ;;
        *)
            log_step "VALIDATION" "ERROR" "Invalid network '$NETWORK'. Use 'ghostnet' or 'mainnet'"
            exit 1
            ;;
    esac
    
    if ! [[ "$MAX_LAG" =~ ^[0-9]+$ ]]; then
        log_step "VALIDATION" "ERROR" "Invalid max_lag '$MAX_LAG'. Must be a positive integer"
        exit 1
    fi
    
    log_step "VALIDATION" "SUCCESS" "Maximum acceptable lag: $MAX_LAG blocks"
}

# Check prerequisites
check_prerequisites() {
    log_step "PREREQUISITES" "START" "Checking required tools"
    
    local required_commands=("docker" "curl" "jq")
    validate_prerequisites "${required_commands[@]}"
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_step "PREREQUISITES" "ERROR" "Docker daemon is not running"
        exit 1
    fi
    
    # Check if container exists and is running
    if ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_step "PREREQUISITES" "ERROR" "Container '$CONTAINER_NAME' is not running"
        log_step "PREREQUISITES" "INFO" "Start the node with: docker compose -f docker/compose.${NETWORK}.yml up -d"
        exit 1
    fi
    
    log_step "PREREQUISITES" "SUCCESS" "Container '$CONTAINER_NAME' is running"
}

# Get network head from external source
get_network_head() {
    local network_rpc_url
    
    case "$NETWORK" in
        "ghostnet")
            network_rpc_url="https://ghostnet.teztnets.xyz"
            ;;
        "mainnet")
            network_rpc_url="https://mainnet.api.tez.ie"
            ;;
    esac
    
    log_step "NETWORK_HEAD" "START" "Fetching current network head from $network_rpc_url"
    
    local network_head
    if network_head=$(curl -s --max-time 10 "$network_rpc_url/chains/main/blocks/head" | jq -r '.header.level' 2>/dev/null); then
        if [[ "$network_head" =~ ^[0-9]+$ ]]; then
            log_step "NETWORK_HEAD" "SUCCESS" "Network head: $network_head"
            echo "$network_head"
        else
            log_step "NETWORK_HEAD" "ERROR" "Invalid network head response: $network_head"
            return 1
        fi
    else
        log_step "NETWORK_HEAD" "ERROR" "Failed to fetch network head from $network_rpc_url"
        return 1
    fi
}

# Get local node head
get_local_head() {
    log_step "LOCAL_HEAD" "START" "Fetching local node head"
    
    local local_head
    if local_head=$(docker exec "$CONTAINER_NAME" tezos-client rpc get /chains/main/blocks/head/header 2>/dev/null | jq -r '.level' 2>/dev/null); then
        if [[ "$local_head" =~ ^[0-9]+$ ]]; then
            log_step "LOCAL_HEAD" "SUCCESS" "Local head: $local_head"
            echo "$local_head"
        else
            log_step "LOCAL_HEAD" "ERROR" "Invalid local head response: $local_head"
            return 1
        fi
    else
        log_step "LOCAL_HEAD" "ERROR" "Failed to get local node head - node may not be ready"
        return 1
    fi
}

# Check if node is bootstrapped
check_bootstrapped() {
    log_step "BOOTSTRAP_CHECK" "START" "Checking if node is bootstrapped"
    
    if docker exec "$CONTAINER_NAME" tezos-client bootstrapped >/dev/null 2>&1; then
        log_step "BOOTSTRAP_CHECK" "SUCCESS" "Node is bootstrapped"
        return 0
    else
        log_step "BOOTSTRAP_CHECK" "INFO" "Node is not yet bootstrapped"
        return 1
    fi
}

# Calculate and check head lag
check_head_lag() {
    local network_head local_head lag
    
    if ! network_head=$(get_network_head); then
        return 1
    fi
    
    if ! local_head=$(get_local_head); then
        return 1
    fi
    
    lag=$((network_head - local_head))
    
    log_step "HEAD_LAG" "INFO" "Head lag calculation: $network_head - $local_head = $lag blocks"
    
    if [ "$lag" -le "$MAX_LAG" ]; then
        log_step "HEAD_LAG" "SUCCESS" "Head lag is acceptable: $lag blocks (max: $MAX_LAG)"
        return 0
    else
        log_step "HEAD_LAG" "WARNING" "Head lag is high: $lag blocks (max: $MAX_LAG)"
        return 1
    fi
}

# Get node sync status and statistics
get_sync_stats() {
    log_step "SYNC_STATS" "START" "Gathering node synchronization statistics"
    
    # Get node status
    local node_status
    if node_status=$(docker exec "$CONTAINER_NAME" tezos-client rpc get /chains/main/blocks/head 2>/dev/null); then
        local timestamp level hash
        timestamp=$(echo "$node_status" | jq -r '.header.timestamp' 2>/dev/null || echo "unknown")
        level=$(echo "$node_status" | jq -r '.header.level' 2>/dev/null || echo "unknown")
        hash=$(echo "$node_status" | jq -r '.hash' 2>/dev/null || echo "unknown")
        
        log_step "SYNC_STATS" "INFO" "Block level: $level"
        log_step "SYNC_STATS" "INFO" "Block timestamp: $timestamp"
        log_step "SYNC_STATS" "INFO" "Block hash: ${hash:0:20}..."
    fi
    
    # Get peer count
    local peer_count
    if peer_count=$(docker exec "$CONTAINER_NAME" tezos-client rpc get /network/connections 2>/dev/null | jq '. | length' 2>/dev/null); then
        log_step "SYNC_STATS" "INFO" "Connected peers: $peer_count"
        
        if [ "$peer_count" -lt 5 ]; then
            log_step "SYNC_STATS" "WARNING" "Low peer count: $peer_count (recommended: 10+)"
        fi
    fi
    
    # Get mempool size
    local mempool_size
    if mempool_size=$(docker exec "$CONTAINER_NAME" tezos-client rpc get /chains/main/mempool/pending_operations 2>/dev/null | jq '. | length' 2>/dev/null); then
        log_step "SYNC_STATS" "INFO" "Mempool size: $mempool_size operations"
    fi
}

# Monitor synchronization continuously
monitor_sync() {
    local check_count=0
    local consecutive_good=0
    local required_consecutive=3
    
    log_step "SYNC_MONITOR" "START" "Monitoring synchronization (max ${MAX_CHECKS} checks, ${CHECK_INTERVAL}s interval)"
    
    while [ $check_count -lt $MAX_CHECKS ]; do
        check_count=$((check_count + 1))
        log_step "SYNC_MONITOR" "INFO" "Check $check_count/$MAX_CHECKS"
        
        # Check if bootstrapped first
        if check_bootstrapped && check_head_lag; then
            consecutive_good=$((consecutive_good + 1))
            log_step "SYNC_MONITOR" "SUCCESS" "Sync check passed ($consecutive_good/$required_consecutive consecutive)"
            
            if [ $consecutive_good -ge $required_consecutive ]; then
                log_step "SYNC_MONITOR" "SUCCESS" "Node is well synchronized ($consecutive_good consecutive good checks)"
                get_sync_stats
                return 0
            fi
        else
            consecutive_good=0
            log_step "SYNC_MONITOR" "INFO" "Sync check failed, resetting consecutive counter"
        fi
        
        if [ $check_count -lt $MAX_CHECKS ]; then
            log_step "SYNC_MONITOR" "INFO" "Waiting ${CHECK_INTERVAL}s before next check..."
            sleep $CHECK_INTERVAL
        fi
    done
    
    log_step "SYNC_MONITOR" "ERROR" "Node failed to achieve stable synchronization after $MAX_CHECKS checks"
    get_sync_stats
    return 1
}

# Quick single check (non-blocking)
quick_check() {
    log_step "QUICK_CHECK" "START" "Performing single synchronization check"
    
    get_sync_stats
    
    if check_bootstrapped && check_head_lag; then
        log_step "QUICK_CHECK" "SUCCESS" "Node is synchronized"
        return 0
    else
        log_step "QUICK_CHECK" "WARNING" "Node is not optimally synchronized"
        return 1
    fi
}

# Show usage information
show_usage() {
    cat << EOF
Tezos Node Synchronization Check

Usage: $0 [network] [max_lag] [--quick|--monitor]
  
Parameters:
  network   Network to check (ghostnet|mainnet) [default: ghostnet]
  max_lag   Maximum acceptable head lag in blocks [default: 2]
  
Modes:
  --quick   Single check and exit (default)
  --monitor Continuous monitoring until stable sync achieved
  
Examples:
  $0                          # Quick check on ghostnet with max lag 2
  $0 mainnet 5                # Quick check on mainnet with max lag 5  
  $0 ghostnet 2 --monitor     # Monitor ghostnet until stable
  
Exit codes:
  0  Node is synchronized within acceptable lag
  1  Node is not synchronized or lag too high
  2  Error in script execution
EOF
}

# Main execution
main() {
    local mode="quick"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --monitor)
                mode="monitor"
                shift
                ;;
            --quick)
                mode="quick"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
    
    log_system_info
    
    validate_parameters
    check_prerequisites
    
    case "$mode" in
        "monitor")
            monitor_sync
            ;;
        "quick")
            quick_check
            ;;
    esac
}

# Execute main function
main "$@"