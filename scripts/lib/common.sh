#!/usr/bin/env bash
# Common functions and utilities for Tezos baker scripts

# =============================================================================
# ENVIRONMENT LOADING
# =============================================================================

load_env() {
    if [ -f .env ]; then
        set -a
        source <(grep -v '^#' .env | sed -e '/^\s*$/d' -e "s/^\([^=]*\)=\(.*\)$/\1=\"\2\"/" -e 's/=""/=/g')
        set +a
    fi
}

# =============================================================================
# COLORS
# =============================================================================

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================================================
# LOGGING
# =============================================================================

log_info() {
    echo -e "${GRAY}$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')${NC} ${BLUE}INFO${NC}  $1"
}

log_warn() {
    echo -e "${GRAY}$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')${NC} ${YELLOW}WARN${NC}  $1"
}

log_error() {
    echo -e "${GRAY}$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')${NC} ${RED}ERROR${NC} $1"
}

log_success() {
    echo -e "${GRAY}$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')${NC} ${GREEN}SUCCESS${NC} $1"
}

# =============================================================================
# CONFIGURATION
# =============================================================================

get_container_name() {
    echo "${CONTAINER_PREFIX:-tezos}-node"
}

get_baker_container_name() {
    echo "${CONTAINER_PREFIX:-tezos}-baker"
}

get_rpc_endpoint() {
    echo "http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}"
}

# =============================================================================
# RPC API FUNCTIONS
# =============================================================================

# Get block header from node
rpc_get_block_head() {
    local endpoint=$(get_rpc_endpoint)
    curl -s "$endpoint/chains/main/blocks/head/header" 2>/dev/null
}

# Get block level
rpc_get_block_level() {
    rpc_get_block_head | jq -r '.level // 0' 2>/dev/null || echo "0"
}

# Get block timestamp
rpc_get_block_timestamp() {
    rpc_get_block_head | jq -r '.timestamp // ""' 2>/dev/null || echo ""
}

# Get network peer count
rpc_get_peer_count() {
    local endpoint=$(get_rpc_endpoint)
    curl -s "$endpoint/network/connections" 2>/dev/null | jq 'length // 0' 2>/dev/null || echo "0"
}

# Get network connections
rpc_get_connections() {
    local endpoint=$(get_rpc_endpoint)
    curl -s "$endpoint/network/connections" 2>/dev/null
}

# Get chain ID
rpc_get_chain_id() {
    local endpoint=$(get_rpc_endpoint)
    curl -s "$endpoint/chains/main/chain_id" 2>/dev/null | tr -d '"'
}

# =============================================================================
# DOCKER FUNCTIONS
# =============================================================================

# Check if node container is running
is_node_running() {
    docker ps | grep -q "$(get_container_name)"
}

# Check if baker container is running
is_baker_running() {
    docker ps | grep -q "$(get_baker_container_name)"
}

# =============================================================================
# TIME FUNCTIONS
# =============================================================================

# Calculate time difference in seconds between block timestamp and now
get_sync_lag() {
    local block_timestamp="$1"

    if [ -z "$block_timestamp" ] || [ "$block_timestamp" = "null" ]; then
        echo "999999"
        return
    fi

    local block_time=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$block_timestamp" "+%s" 2>/dev/null || echo "0")
    local current_time=$(date "+%s")

    if [ "$block_time" -eq 0 ]; then
        echo "999999"
    else
        echo $((current_time - block_time))
    fi
}

# Convert seconds to human readable format
seconds_to_human() {
    local seconds=$1

    if [ "$seconds" -ge 3600 ]; then
        echo "$((seconds / 3600))h"
    elif [ "$seconds" -ge 60 ]; then
        echo "$((seconds / 60))m"
    else
        echo "${seconds}s"
    fi
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Auto-load environment when sourced
load_env
