#!/bin/bash

# Tezos Node Production Readiness Verification Script

# Load environment variables
if [ -f .env ]; then
    set -a
    source <(grep -v '^#' .env | sed -e '/^\s*$/d' -e 's/^\([^=]*\)=\(.*\)$/\1="\2"/' -e 's/=""/=/g')
    set +a
fi

RPC_ENDPOINT="http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

echo "════════════════════════════════════════════════════════"
echo "  TEZOS NODE PRODUCTION READINESS VERIFICATION"
echo "════════════════════════════════════════════════════════"
echo ""

# Test function
test_check() {
    local name="$1"
    local status="$2"
    local message="$3"
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $name"
        [ -n "$message" ] && echo "  → $message"
        ((PASS++))
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠${NC} $name"
        [ -n "$message" ] && echo "  → $message"
        ((WARN++))
    else
        echo -e "${RED}✗${NC} $name"
        [ -n "$message" ] && echo "  → $message"
        ((FAIL++))
    fi
}

echo "1. DOCKER CONTAINER CHECKS"
echo "────────────────────────────────────────────────────────"

# Check if container is running
if docker ps | grep -q "${CONTAINER_PREFIX:-tezos}-node"; then
    CONTAINER_ID=$(docker ps --filter "name=${CONTAINER_PREFIX:-tezos}-node" --format "{{.ID}}")
    UPTIME=$(docker ps --filter "name=${CONTAINER_PREFIX:-tezos}-node" --format "{{.Status}}")
    test_check "Container Running" "PASS" "$UPTIME"
    
    # Check container health
    CONTAINER_STATE=$(docker inspect --format='{{.State.Status}}' ${CONTAINER_PREFIX:-tezos}-node 2>/dev/null)
    if [ "$CONTAINER_STATE" = "running" ]; then
        test_check "Container State" "PASS" "Status: $CONTAINER_STATE"
    else
        test_check "Container State" "FAIL" "Status: $CONTAINER_STATE"
    fi
    
    # Check restart count
    RESTART_COUNT=$(docker inspect --format='{{.RestartCount}}' ${CONTAINER_PREFIX:-tezos}-node 2>/dev/null)
    if [ "$RESTART_COUNT" = "0" ]; then
        test_check "Container Stability" "PASS" "No restarts"
    else
        test_check "Container Stability" "WARN" "Restart count: $RESTART_COUNT"
    fi
else
    test_check "Container Running" "FAIL" "Node container not found"
    echo ""
    echo "Cannot continue verification without running container."
    exit 1
fi

echo ""
echo "2. NETWORK CONFIGURATION"
echo "────────────────────────────────────────────────────────"

# Check ports
for PORT in ${RPC_PORT:-8732} ${P2P_PORT:-9732}; do
    if docker port ${CONTAINER_PREFIX:-tezos}-node | grep -q "$PORT"; then
        test_check "Port $PORT Exposed" "PASS" "$(docker port ${CONTAINER_PREFIX:-tezos}-node | grep $PORT)"
    else
        test_check "Port $PORT Exposed" "FAIL" "Port not exposed"
    fi
done

# Check RPC accessibility
if curl -s --max-time 5 $RPC_ENDPOINT/chains/main/chain_id > /dev/null 2>&1; then
    CHAIN_ID=$(curl -s $RPC_ENDPOINT/chains/main/chain_id | tr -d '"')
    test_check "RPC Endpoint Accessible" "PASS" "Chain: $CHAIN_ID"
else
    test_check "RPC Endpoint Accessible" "FAIL" "Cannot connect to RPC"
fi

# Check network connections
CONN_COUNT=$(curl -s $RPC_ENDPOINT/network/connections 2>/dev/null | jq 'length' 2>/dev/null)
if [ -n "$CONN_COUNT" ] && [ "$CONN_COUNT" != "null" ]; then
    if [ "$CONN_COUNT" -ge 10 ]; then
        test_check "Peer Connections" "PASS" "$CONN_COUNT peers (healthy: ≥10)"
    elif [ "$CONN_COUNT" -ge 5 ]; then
        test_check "Peer Connections" "WARN" "$CONN_COUNT peers (minimum: 5, recommended: ≥10)"
    else
        test_check "Peer Connections" "FAIL" "$CONN_COUNT peers (too few, minimum: 5)"
    fi
else
    test_check "Peer Connections" "FAIL" "Cannot fetch peer count"
fi

echo ""
echo "3. BLOCKCHAIN SYNCHRONIZATION"
echo "────────────────────────────────────────────────────────"

# Get current head
HEAD=$(curl -s $RPC_ENDPOINT/chains/main/blocks/head/header 2>/dev/null)
if [ -n "$HEAD" ]; then
    BLOCK_LEVEL=$(echo $HEAD | jq -r '.level // "N/A"')
    BLOCK_TIMESTAMP=$(echo $HEAD | jq -r '.timestamp // "N/A"')
    
    test_check "Block Data Available" "PASS" "Level: $BLOCK_LEVEL"
    
    # Check block timestamp (should be recent)
    if [ "$BLOCK_TIMESTAMP" != "N/A" ]; then
        BLOCK_TIME=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$BLOCK_TIMESTAMP" "+%s" 2>/dev/null)
        NOW=$(date "+%s")
        AGE=$((NOW - BLOCK_TIME))
        
        if [ $AGE -lt 60 ]; then
            test_check "Chain Synchronized" "PASS" "Head is ${AGE}s old (synced)"
        elif [ $AGE -lt 300 ]; then
            test_check "Chain Synchronized" "WARN" "Head is ${AGE}s old (catching up)"
        else
            test_check "Chain Synchronized" "FAIL" "Head is ${AGE}s old (not synced)"
        fi
    fi
else
    test_check "Block Data Available" "FAIL" "Cannot fetch block data"
fi

# Check for sync status in logs
if docker logs --tail 20 ${CONTAINER_PREFIX:-tezos}-node 2>&1 | grep -q "head is now"; then
    test_check "Processing Blocks" "PASS" "Real-time block processing detected"
elif docker logs --tail 20 ${CONTAINER_PREFIX:-tezos}-node 2>&1 | grep -q "synchronizing"; then
    test_check "Processing Blocks" "WARN" "Still synchronizing"
else
    test_check "Processing Blocks" "WARN" "Cannot determine sync status from logs"
fi

echo ""
echo "4. DATA INTEGRITY"
echo "────────────────────────────────────────────────────────"

# Check config file
if [ -f "${DATA_DIR:-data}/config.json" ]; then
    test_check "Config File Exists" "PASS" "${DATA_DIR:-data}/config.json"
    
    # Validate config JSON
    if jq empty "${DATA_DIR:-data}/config.json" 2>/dev/null; then
        test_check "Config JSON Valid" "PASS" "Syntax correct"
    else
        test_check "Config JSON Valid" "FAIL" "Syntax error"
    fi
    
    # Check network in config
    NETWORK=$(jq -r '.network // "unknown"' "${DATA_DIR:-data}/config.json" 2>/dev/null)
    if [ "$NETWORK" = "${TEZOS_NETWORK:-ghostnet}" ]; then
        test_check "Network Configuration" "PASS" "Network: $NETWORK"
    else
        test_check "Network Configuration" "FAIL" "Config: $NETWORK, Expected: ${TEZOS_NETWORK:-ghostnet}"
    fi
    
    # Check history mode
    HISTORY=$(jq -r '.shell.history_mode // "unknown"' "${DATA_DIR:-data}/config.json" 2>/dev/null)
    test_check "History Mode" "PASS" "Mode: $HISTORY"
else
    test_check "Config File Exists" "FAIL" "Config file not found"
fi

# Check identity file
if [ -f "${DATA_DIR:-data}/identity.json" ]; then
    test_check "Identity File Exists" "PASS" "${DATA_DIR:-data}/identity.json"
    
    # Validate identity JSON
    if jq empty "${DATA_DIR:-data}/identity.json" 2>/dev/null; then
        PEER_ID=$(jq -r '.peer_id // "N/A"' "${DATA_DIR:-data}/identity.json" 2>/dev/null)
        test_check "Identity Valid" "PASS" "Peer ID: ${PEER_ID:0:20}..."
    else
        test_check "Identity Valid" "FAIL" "Invalid identity file"
    fi
else
    test_check "Identity File Exists" "FAIL" "Identity file not found"
fi

# Check context directory
if [ -d "${DATA_DIR:-data}/context" ]; then
    CONTEXT_SIZE=$(du -sh "${DATA_DIR:-data}/context" 2>/dev/null | cut -f1)
    test_check "Context Directory" "PASS" "Size: $CONTEXT_SIZE"
else
    test_check "Context Directory" "FAIL" "Context directory not found"
fi

echo ""
echo "5. PROTOCOL & VERSION"
echo "────────────────────────────────────────────────────────"

# Check protocol
PROTOCOL=$(echo $HEAD | jq -r '.protocol // "N/A"')
if [ "$PROTOCOL" != "N/A" ]; then
    test_check "Protocol Hash" "PASS" "${PROTOCOL:0:15}..."
else
    test_check "Protocol Hash" "FAIL" "Cannot determine protocol"
fi

# Check Octez version from container
OCTEZ_VERSION_ACTUAL=$(docker exec ${CONTAINER_PREFIX:-tezos}-node octez-node --version 2>/dev/null | head -1)
if [ -n "$OCTEZ_VERSION_ACTUAL" ]; then
    test_check "Octez Version" "PASS" "$OCTEZ_VERSION_ACTUAL"
else
    test_check "Octez Version" "WARN" "Cannot determine version"
fi

echo ""
echo "6. RESOURCE USAGE"
echo "────────────────────────────────────────────────────────"

# Check memory usage
MEM_USAGE=$(docker stats --no-stream --format "{{.MemUsage}}" ${CONTAINER_PREFIX:-tezos}-node 2>/dev/null)
if [ -n "$MEM_USAGE" ]; then
    test_check "Memory Usage" "PASS" "$MEM_USAGE"
else
    test_check "Memory Usage" "WARN" "Cannot determine memory usage"
fi

# Check CPU usage
CPU_USAGE=$(docker stats --no-stream --format "{{.CPUPerc}}" ${CONTAINER_PREFIX:-tezos}-node 2>/dev/null)
if [ -n "$CPU_USAGE" ]; then
    test_check "CPU Usage" "PASS" "$CPU_USAGE"
else
    test_check "CPU Usage" "WARN" "Cannot determine CPU usage"
fi

# Check disk usage
DISK_USAGE=$(du -sh "${DATA_DIR:-data}" 2>/dev/null | cut -f1)
if [ -n "$DISK_USAGE" ]; then
    test_check "Disk Usage" "PASS" "Data dir: $DISK_USAGE"
else
    test_check "Disk Usage" "WARN" "Cannot determine disk usage"
fi

echo ""
echo "7. SECURITY CHECKS"
echo "────────────────────────────────────────────────────────"

# Check RPC ACL configuration
ACL_CONFIG=$(jq -r '.rpc.acl // "none"' "${DATA_DIR:-data}/config.json" 2>/dev/null)
if [ "$ACL_CONFIG" != "none" ] && [ "$ACL_CONFIG" != "null" ]; then
    test_check "RPC ACL Configured" "PASS" "ACL rules present"
else
    test_check "RPC ACL Configured" "WARN" "No ACL configured (consider for production)"
fi

# Check if RPC is exposed externally
RPC_ADDR=$(jq -r '.rpc["listen-addrs"][0] // "unknown"' "${DATA_DIR:-data}/config.json" 2>/dev/null)
if echo "$RPC_ADDR" | grep -q "0.0.0.0"; then
    test_check "RPC Exposure" "WARN" "Listening on all interfaces (ensure firewall configured)"
elif echo "$RPC_ADDR" | grep -q "127.0.0.1"; then
    test_check "RPC Exposure" "PASS" "Localhost only (secure)"
else
    test_check "RPC Exposure" "PASS" "Address: $RPC_ADDR"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  SUMMARY"
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Passed:${NC}  $PASS"
echo -e "${YELLOW}⚠ Warnings:${NC} $WARN"
echo -e "${RED}✗ Failed:${NC}  $FAIL"
echo ""

TOTAL=$((PASS + WARN + FAIL))
if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
    echo -e "${GREEN}🎉 PRODUCTION READY${NC} - All checks passed!"
    exit 0
elif [ $FAIL -eq 0 ]; then
    echo -e "${YELLOW}⚠️  NEEDS ATTENTION${NC} - $WARN warnings found"
    echo "Review warnings before production deployment."
    exit 0
else
    echo -e "${RED}❌ NOT READY${NC} - $FAIL critical issues found"
    echo "Fix critical issues before production deployment."
    exit 1
fi
