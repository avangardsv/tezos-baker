#!/bin/bash

# Tezos Node Health Check Script
# Performs comprehensive health checks for Tezos node, baker, and endorser

set -euo pipefail

# Configuration
RPC_ENDPOINT="http://127.0.0.1:8732"
TIMEOUT=10
MAX_HEAD_LAG=${MAX_HEAD_LAG:-5}

# Function to check if RPC is responding
check_rpc() {
    if timeout "$TIMEOUT" curl -s "$RPC_ENDPOINT/chains/main/blocks/head/header" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check node bootstrapping status
check_bootstrapped() {
    if timeout "$TIMEOUT" tezos-client --endpoint "$RPC_ENDPOINT" bootstrapped >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check head lag
check_head_lag() {
    local network_head local_head lag
    
    # Get network head from external source based on network
    case "${TEZOS_NETWORK:-ghostnet}" in
        "mainnet")
            network_head=$(timeout "$TIMEOUT" curl -s "https://mainnet.api.tez.ie/chains/main/blocks/head/header" 2>/dev/null | jq -r '.level' 2>/dev/null || echo "0")
            ;;
        "ghostnet")
            network_head=$(timeout "$TIMEOUT" curl -s "https://ghostnet.teztnets.xyz/chains/main/blocks/head/header" 2>/dev/null | jq -r '.level' 2>/dev/null || echo "0")
            ;;
        *)
            network_head="0"
            ;;
    esac
    
    # Get local head
    local_head=$(timeout "$TIMEOUT" curl -s "$RPC_ENDPOINT/chains/main/blocks/head/header" 2>/dev/null | jq -r '.level' 2>/dev/null || echo "0")
    
    # Calculate lag
    if [[ "$network_head" =~ ^[0-9]+$ ]] && [[ "$local_head" =~ ^[0-9]+$ ]] && [ "$network_head" -gt 0 ] && [ "$local_head" -gt 0 ]; then
        lag=$((network_head - local_head))
        
        if [ "$lag" -le "$MAX_HEAD_LAG" ]; then
            echo "Head lag: $lag blocks (acceptable)"
            return 0
        else
            echo "Head lag: $lag blocks (too high, max: $MAX_HEAD_LAG)"
            return 1
        fi
    else
        echo "Unable to determine head lag"
        return 1
    fi
}

# Function to check process health
check_process() {
    local process_name="$1"
    
    if pgrep -f "$process_name" >/dev/null 2>&1; then
        echo "$process_name: running"
        return 0
    else
        echo "$process_name: not running"
        return 1
    fi
}

# Function to check peer connections
check_peers() {
    local peer_count
    
    peer_count=$(timeout "$TIMEOUT" curl -s "$RPC_ENDPOINT/network/connections" 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
    
    if [[ "$peer_count" =~ ^[0-9]+$ ]] && [ "$peer_count" -gt 0 ]; then
        echo "Peers: $peer_count connected"
        if [ "$peer_count" -lt 5 ]; then
            echo "Warning: Low peer count"
            return 1
        else
            return 0
        fi
    else
        echo "Peers: unable to determine"
        return 1
    fi
}

# Function to check disk space
check_disk_space() {
    local data_dir="/var/lib/tezos"
    local min_free_gb=5
    
    if [ -d "$data_dir" ]; then
        local available_kb free_gb
        available_kb=$(df "$data_dir" | tail -1 | awk '{print $4}')
        free_gb=$((available_kb / 1024 / 1024))
        
        echo "Disk space: ${free_gb}GB free"
        
        if [ "$free_gb" -lt "$min_free_gb" ]; then
            echo "Warning: Low disk space (< ${min_free_gb}GB)"
            return 1
        else
            return 0
        fi
    else
        echo "Data directory not found"
        return 1
    fi
}

# Function to perform node health check
check_node_health() {
    local errors=0
    
    echo "=== Node Health Check ==="
    
    # RPC connectivity
    if check_rpc; then
        echo "✓ RPC responding"
    else
        echo "✗ RPC not responding"
        errors=$((errors + 1))
    fi
    
    # Bootstrap status
    if check_bootstrapped; then
        echo "✓ Node bootstrapped"
    else
        echo "✗ Node not bootstrapped"
        errors=$((errors + 1))
    fi
    
    # Head lag
    if check_head_lag; then
        echo "✓ Head lag acceptable"
    else
        echo "⚠ Head lag high or undetermined"
        # Don't increment errors for head lag warnings
    fi
    
    # Peer connections
    if check_peers; then
        echo "✓ Peer connections healthy"
    else
        echo "⚠ Peer connection issues"
        # Don't increment errors for peer warnings
    fi
    
    # Disk space
    if check_disk_space; then
        echo "✓ Disk space sufficient"
    else
        echo "⚠ Disk space warning"
        # Don't increment errors for disk warnings
    fi
    
    # Process check
    if check_process "tezos-node"; then
        echo "✓ Node process running"
    else
        echo "✗ Node process not running"
        errors=$((errors + 1))
    fi
    
    return "$errors"
}

# Function to perform baker health check
check_baker_health() {
    local errors=0
    
    echo "=== Baker Health Check ==="
    
    # Process check
    if check_process "tezos-baker"; then
        echo "✓ Baker process running"
    else
        echo "✗ Baker process not running"
        errors=$((errors + 1))
    fi
    
    # Check if baker key exists (if RPC is available)
    if check_rpc; then
        local baker_alias="${BAKER_ALIAS:-baker}"
        if timeout "$TIMEOUT" tezos-client --endpoint "$RPC_ENDPOINT" show address "$baker_alias" >/dev/null 2>&1; then
            echo "✓ Baker key '$baker_alias' available"
        else
            echo "✗ Baker key '$baker_alias' not found"
            errors=$((errors + 1))
        fi
    fi
    
    return "$errors"
}

# Function to perform endorser health check
check_endorser_health() {
    local errors=0
    
    echo "=== Endorser Health Check ==="
    
    # Process check
    if check_process "tezos-endorser"; then
        echo "✓ Endorser process running"
    else
        echo "✗ Endorser process not running"
        errors=$((errors + 1))
    fi
    
    return "$errors"
}

# Main health check
main() {
    local component="${1:-all}"
    local total_errors=0
    
    echo "Tezos Health Check - $(date)"
    echo "Network: ${TEZOS_NETWORK:-unknown}"
    echo "Component: $component"
    echo ""
    
    case "$component" in
        "node")
            check_node_health || total_errors=$((total_errors + $?))
            ;;
        "baker")
            check_baker_health || total_errors=$((total_errors + $?))
            ;;
        "endorser")
            check_endorser_health || total_errors=$((total_errors + $?))
            ;;
        "all"|*)
            check_node_health || total_errors=$((total_errors + $?))
            echo ""
            check_baker_health || total_errors=$((total_errors + $?))
            echo ""
            check_endorser_health || total_errors=$((total_errors + $?))
            ;;
    esac
    
    echo ""
    if [ "$total_errors" -eq 0 ]; then
        echo "✓ Health check passed"
        exit 0
    else
        echo "✗ Health check failed with $total_errors errors"
        exit 1
    fi
}

# Execute main function
main "$@"