#!/usr/bin/env bash

# Tezos Node Production Readiness Verification Script
# Checks 7 categories with 25+ individual tests
#
# Usage: ./scripts/verify-production.sh [--production]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Shared library (colors, logging, helpers)
source "${SCRIPT_DIR}/lib/common.sh"

# Load environment from project root (common.sh loads CWD)
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# Configuration with defaults
CONTAINER_PREFIX="${CONTAINER_PREFIX:-tezos}"
CONTAINER_NAME="${CONTAINER_PREFIX}-node"
RPC_PORT="${RPC_PORT:-8732}"
P2P_PORT="${P2P_PORT:-9732}"
RPC_ADDR="${RPC_ADDR:-127.0.0.1}"
DATA_DIR="${DATA_DIR:-./data}"
TEZOS_NETWORK="${TEZOS_NETWORK:-ghostnet}"
OCTEZ_VERSION="${OCTEZ_VERSION:-octez-v23.1}"

# Flags
SHOW_PRODUCTION_REMINDER=false
VERBOSE=false
for arg in "$@"; do
    case "$arg" in
        --production) SHOW_PRODUCTION_REMINDER=true ;;
        -v|--verbose) VERBOSE=true ;;
    esac
done

# Counters
PASSED=0
WARNINGS=0
FAILED=0

# Logging wrappers (use common.sh helpers)
mark_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

mark_warn() {
    log_warn "$1"
    ((WARNINGS++))
}

mark_fail() {
    log_error "$1"
    ((FAILED++))
}

log_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Dependency check
check_dependencies() {
    local deps=("docker" "jq" "curl")
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        mark_fail "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

# Check if container exists
container_exists() {
    docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$" 2>/dev/null
}

# Check if container is running
container_running() {
    docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$" 2>/dev/null
}

# Get container status
get_container_status() {
    docker inspect "${CONTAINER_NAME}" --format='{{.State.Status}}' 2>/dev/null || echo "not-found"
}

# Get restart count
get_restart_count() {
    docker inspect "${CONTAINER_NAME}" --format='{{.RestartCount}}' 2>/dev/null || echo "0"
}

# ============================================
# Category 1: Docker Container Health
# ============================================
verify_container_health() {
    log_section "1. ✅ Docker Container Health"
    
    if ! container_exists; then
        mark_fail "Container ${CONTAINER_NAME} does not exist"
        return
    fi
    
    if ! container_running; then
        mark_fail "Container ${CONTAINER_NAME} is not running"
        return
    fi
    
    mark_pass "Container ${CONTAINER_NAME} exists"
    mark_pass "Container ${CONTAINER_NAME} is running"
    
    local status=$(get_container_status)
    if [ "$status" = "running" ]; then
        mark_pass "Container status: running"
    else
        mark_fail "Container status: $status (expected: running)"
    fi
    
    local restart_count=$(get_restart_count)
    if [ "$restart_count" -eq 0 ]; then
        mark_pass "Restart count: 0 (no unexpected restarts)"
    elif [ "$restart_count" -le 3 ]; then
        mark_warn "Restart count: $restart_count (acceptable, but monitor)"
    else
        mark_fail "Restart count: $restart_count (too many restarts)"
    fi
    
    # Check uptime
    local started=$(docker inspect "${CONTAINER_NAME}" --format='{{.State.StartedAt}}' 2>/dev/null)
    if [ -n "$started" ]; then
        mark_pass "Container started at: $started"
    fi
}

# ============================================
# Category 2: Network Configuration
# ============================================
verify_network() {
    log_section "2. 🌐 Network Configuration"
    
    # Check RPC port
    if docker port "${CONTAINER_NAME}" 2>/dev/null | grep -q "${RPC_PORT}"; then
        mark_pass "RPC port ${RPC_PORT} is exposed"
    else
        mark_fail "RPC port ${RPC_PORT} is not exposed"
    fi
    
    # Check P2P port
    if docker port "${CONTAINER_NAME}" 2>/dev/null | grep -q "${P2P_PORT}"; then
        mark_pass "P2P port ${P2P_PORT} is exposed"
    else
        mark_fail "P2P port ${P2P_PORT} is not exposed"
    fi
    
    # Check RPC endpoint accessibility
    local rpc_url="http://${RPC_ADDR}:${RPC_PORT}"
    if curl -s --max-time 5 "${rpc_url}/chains/main/chain_id" >/dev/null 2>&1; then
        mark_pass "RPC endpoint is accessible at ${rpc_url}"
    else
        mark_fail "RPC endpoint is not accessible at ${rpc_url}"
    fi
    
    # Check peer connections
    local peer_count=0
    local connections=$(curl -s --max-time 5 "${rpc_url}/network/connections" 2>/dev/null)
    if [ -n "$connections" ] && echo "$connections" | jq -e '. | length' >/dev/null 2>&1; then
        peer_count=$(echo "$connections" | jq '. | length' 2>/dev/null || echo "0")
    fi
    
    if [ "$peer_count" -ge 10 ]; then
        mark_pass "Peer connections: $peer_count (healthy: ≥10)"
    elif [ "$peer_count" -ge 5 ]; then
        mark_warn "Peer connections: $peer_count (minimum: 5, recommended: ≥10)"
    else
        mark_fail "Peer connections: $peer_count (minimum: 5 required)"
    fi
}

# ============================================
# Category 3: Blockchain Synchronization
# ============================================
verify_synchronization() {
    log_section "3. ⛓️ Blockchain Synchronization"
    
    local rpc_url="http://${RPC_ADDR}:${RPC_PORT}"
    
    # Check block data accessibility
    local block_data=$(curl -s --max-time 5 "${rpc_url}/chains/main/blocks/head/header" 2>/dev/null)
    if [ -n "$block_data" ] && echo "$block_data" | jq -e '.level' >/dev/null 2>&1; then
        mark_pass "Block data is accessible"
        local level=$(echo "$block_data" | jq -r '.level')
        log_info "Current block level: $level"
    else
        mark_fail "Block data is not accessible"
        return
    fi
    
    # Check head timestamp
    local timestamp=$(echo "$block_data" | jq -r '.timestamp' 2>/dev/null || echo "")
    if [ -n "$timestamp" ] && [ "$timestamp" != "null" ]; then
        # Convert timestamp to seconds since epoch (macOS uses -j -f, Linux uses -d)
        local block_time=""
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS BSD date
            block_time=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "${timestamp}" +%s 2>/dev/null || echo "0")
        else
            # Linux GNU date
            block_time=$(date -d "${timestamp}" +%s 2>/dev/null || echo "0")
        fi
        
        if [ "$block_time" != "0" ] && [ -n "$block_time" ]; then
            local current_time=$(date +%s)
            local age=$((current_time - block_time))
            
            if [ "$age" -lt 60 ]; then
                mark_pass "Head age: ${age} seconds (< 60 seconds - synced)"
            elif [ "$age" -lt 300 ]; then
                mark_warn "Head age: ${age} seconds (< 5 minutes - catching up)"
            else
                mark_fail "Head age: ${age} seconds (> 5 minutes - not synced)"
            fi
        else
            mark_warn "Could not parse timestamp: $timestamp"
        fi
    fi
    
    # Check sync status in logs
    local sync_status=$(docker logs "${CONTAINER_NAME}" 2>&1 | tail -50 | grep -E "synced|synchronizing|head is now" | tail -1 || echo "")
    if [ -n "$sync_status" ]; then
        if echo "$sync_status" | grep -qE "synced|head is now"; then
            mark_pass "Sync status: Active (found in logs)"
        else
            mark_warn "Sync status: Synchronizing (check logs)"
        fi
    else
        mark_warn "Sync status: Could not determine from logs"
    fi
}

# ============================================
# Category 4: Data Integrity
# ============================================
verify_data_integrity() {
    log_section "4. 📁 Data Integrity"
    
    local abs_data_dir="$PROJECT_ROOT/$DATA_DIR"
    
    # Check config file exists
    if [ -f "${abs_data_dir}/config.json" ]; then
        mark_pass "Config file exists"
        
        # Check config is valid JSON
        if jq . "${abs_data_dir}/config.json" >/dev/null 2>&1; then
            mark_pass "Config file is valid JSON"
        else
            mark_fail "Config file is not valid JSON"
            return
        fi
        
        # Check network matches
        local config_network=$(jq -r '.network // empty' "${abs_data_dir}/config.json" 2>/dev/null || echo "")
        if [ "$config_network" = "$TEZOS_NETWORK" ]; then
            mark_pass "Network matches: $TEZOS_NETWORK"
        else
            mark_warn "Network mismatch: config=$config_network, env=$TEZOS_NETWORK"
        fi
        
        # Check history mode
        local history_mode=$(jq -r '.shell.history_mode // empty' "${abs_data_dir}/config.json" 2>/dev/null || echo "")
        if [ -n "$history_mode" ]; then
            mark_pass "History mode: $history_mode"
        else
            mark_warn "History mode not found in config"
        fi
    else
        mark_fail "Config file does not exist: ${abs_data_dir}/config.json"
    fi
    
    # Check identity file
    if [ -f "${abs_data_dir}/identity.json" ]; then
        mark_pass "Identity file exists"
        
        # Check identity has peer_id
        if jq -e '.peer_id' "${abs_data_dir}/identity.json" >/dev/null 2>&1; then
            mark_pass "Identity file has valid peer_id"
        else
            mark_fail "Identity file missing peer_id"
        fi
    else
        mark_fail "Identity file does not exist: ${abs_data_dir}/identity.json"
    fi
    
    # Check context directory
    if [ -d "${abs_data_dir}/context" ]; then
        mark_pass "Context directory exists"
        local context_size=$(du -sh "${abs_data_dir}/context" 2>/dev/null | cut -f1 || echo "0")
        log_info "Context size: $context_size"
    else
        mark_warn "Context directory does not exist (may be initializing)"
    fi
}

# ============================================
# Category 5: Protocol & Version
# ============================================
verify_protocol_version() {
    log_section "5. 🔧 Protocol & Version"
    
    local rpc_url="http://${RPC_ADDR}:${RPC_PORT}"
    
    # Check protocol hash
    local protocol=$(curl -s --max-time 5 "${rpc_url}/chains/main/blocks/head/header" 2>/dev/null | jq -r '.protocol' 2>/dev/null || echo "")
    if [ -n "$protocol" ] && [ "$protocol" != "null" ]; then
        mark_pass "Protocol hash: $protocol"
    else
        mark_fail "Protocol hash not found"
    fi
    
    # Check Octez version
    if container_running; then
        local version=$(docker exec "${CONTAINER_NAME}" octez-node --version 2>/dev/null | head -1 || echo "")
        if [ -n "$version" ]; then
            mark_pass "Octez version: $version"
            
            # Check if version matches expected
            if echo "$version" | grep -q "${OCTEZ_VERSION}"; then
                mark_pass "Version matches expected: ${OCTEZ_VERSION}"
            else
                mark_warn "Version mismatch: expected ${OCTEZ_VERSION}, got $version"
            fi
        else
            mark_warn "Could not determine Octez version"
        fi
    else
        mark_fail "Container not running, cannot check version"
    fi
}

# ============================================
# Category 6: Resource Usage
# ============================================
verify_resources() {
    log_section "6. 💾 Resource Usage"
    
    if ! container_running; then
        mark_fail "Container not running, cannot check resources"
        return
    fi
    
    # Get stats (one-time snapshot)
    local stats=$(docker stats "${CONTAINER_NAME}" --no-stream --format "{{.MemUsage}}|{{.CPUPerc}}" 2>/dev/null || echo "||")
    local mem_usage=$(echo "$stats" | cut -d'|' -f1)
    local cpu_perc=$(echo "$stats" | cut -d'|' -f2 | sed 's/%//')
    
    if [ -n "$mem_usage" ] && [ "$mem_usage" != "" ]; then
        log_info "Memory usage: $mem_usage"
        # Extract numeric value (rough check)
        local mem_mb=$(echo "$mem_usage" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1 || echo "0")
        if [ -n "$mem_mb" ]; then
            if (( $(echo "$mem_mb < 2048" | bc -l 2>/dev/null || echo "1") )); then
                mark_pass "Memory usage reasonable (< 2GB)"
            elif (( $(echo "$mem_mb < 8192" | bc -l 2>/dev/null || echo "1") )); then
                mark_pass "Memory usage acceptable (< 8GB)"
            else
                mark_warn "Memory usage high: ${mem_mb}MB (monitor closely)"
            fi
        fi
    else
        mark_warn "Could not determine memory usage"
    fi
    
    if [ -n "$cpu_perc" ] && [ "$cpu_perc" != "" ]; then
        log_info "CPU usage: ${cpu_perc}%"
        # CPU usage is expected to be high during sync
        if (( $(echo "$cpu_perc < 20" | bc -l 2>/dev/null || echo "1") )); then
            mark_pass "CPU usage normal (< 20% - synced)"
        elif (( $(echo "$cpu_perc < 80" | bc -l 2>/dev/null || echo "1") )); then
            mark_warn "CPU usage moderate (${cpu_perc}% - may be syncing)"
        else
            mark_warn "CPU usage high (${cpu_perc}% - likely syncing, normal during catch-up)"
        fi
    else
        mark_warn "Could not determine CPU usage"
    fi
    
    # Check disk usage
    local abs_data_dir="$PROJECT_ROOT/$DATA_DIR"
    if [ -d "$abs_data_dir" ]; then
        local disk_usage=$(du -sh "$abs_data_dir" 2>/dev/null | cut -f1 || echo "0")
        log_info "Data directory size: $disk_usage"
        mark_pass "Disk usage tracked"
    else
        mark_fail "Data directory does not exist"
    fi
}

# ============================================
# Category 7: Security Configuration
# ============================================
verify_security() {
    log_section "7. 🔒 Security Configuration"
    
    local abs_data_dir="$PROJECT_ROOT/$DATA_DIR"
    
    # Check RPC ACL
    if [ -f "${abs_data_dir}/config.json" ]; then
        local acl=$(jq -r '.rpc.acl // empty' "${abs_data_dir}/config.json" 2>/dev/null || echo "")
        if [ -n "$acl" ] && [ "$acl" != "null" ] && [ "$acl" != "[]" ]; then
            mark_pass "RPC ACL is configured"
        else
            mark_warn "RPC ACL is not configured (may cause connection issues)"
        fi
        
        # Check RPC listen address
        local listen_addrs=$(jq -r '.rpc.listen-addrs[] // empty' "${abs_data_dir}/config.json" 2>/dev/null || echo "")
        if echo "$listen_addrs" | grep -q "0.0.0.0"; then
            if [ "$TEZOS_NETWORK" = "ghostnet" ] || [ "$TEZOS_NETWORK" = "testnet" ]; then
                mark_warn "RPC listening on 0.0.0.0 (acceptable for testnet with firewall)"
            else
                mark_fail "RPC listening on 0.0.0.0 (security risk for mainnet - use firewall)"
            fi
        elif echo "$listen_addrs" | grep -q "127.0.0.1"; then
            mark_pass "RPC listening on 127.0.0.1 (secure)"
        else
            log_info "RPC listen address: $listen_addrs"
        fi
    else
        mark_fail "Config file not found, cannot verify security"
    fi
}

# ============================================
# Main execution
# ============================================
main() {
    cd "$PROJECT_ROOT"
    
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Tezos Node Production Readiness Verification ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ "$VERBOSE" = true ]; then
        log_info "Verbose mode enabled"
    fi

    check_dependencies
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        mark_fail "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        mark_fail "Docker daemon is not running"
        exit 1
    fi
    
    # Run all verification categories
    verify_container_health
    verify_network
    verify_synchronization
    verify_data_integrity
    verify_protocol_version
    verify_resources
    verify_security
    
    # Summary
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Verification Summary${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✓ Passed:${NC}  ${PASSED}"
    echo -e "${YELLOW}⚠ Warnings:${NC} ${WARNINGS}"
    echo -e "${RED}✗ Failed:${NC}  ${FAILED}"
    echo ""
    
    # Final status
    if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 PRODUCTION READY - All checks passed!${NC}"
        echo ""
        exit 0
    elif [ $FAILED -eq 0 ]; then
        echo -e "${YELLOW}⚠️  NEEDS ATTENTION - ${WARNINGS} warning(s) found${NC}"
        echo "Review warnings before production deployment."
        echo ""
        if [ "$SHOW_PRODUCTION_REMINDER" = true ]; then
            echo -e "${YELLOW}⚠️  PRODUCTION REMINDER:${NC}"
            echo "Before deploying to mainnet, ensure:"
            echo "  - Firewall configured (UFW/iptables)"
            echo "  - RPC ACL rules strict (whitelist only)"
            echo "  - HTTPS/TLS for external RPC access"
            echo "  - Separate signer for baker keys (hardware wallet)"
            echo "  - Monitoring & alerts configured"
            echo "  - Backup strategy in place"
            echo ""
        fi
        exit 0
    else
        echo -e "${RED}❌ NOT READY - ${FAILED} critical issue(s) found${NC}"
        echo "Fix critical issues before production deployment."
        echo ""
        exit 1
    fi
}

main "$@"
