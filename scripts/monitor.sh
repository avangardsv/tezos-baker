#!/bin/bash
# Tezos node monitor - displays current status

# Load shared library
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/lib/common.sh"

clear

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         TEZOS NODE MONITOR - GHOSTNET                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if node is running
if ! is_node_running; then
    echo -e "${RED}❌ Node is not running${NC}"
    echo "Run: npm run node:start"
    exit 1
fi

echo -e "${GREEN}✅ Node is running${NC}"
echo ""

# Get current head
echo -e "${YELLOW}📊 BLOCKCHAIN STATUS:${NC}"
HEAD=$(rpc_get_block_head)

if [ $? -eq 0 ] && [ -n "$HEAD" ]; then
    LEVEL=$(echo $HEAD | jq -r '.level // "N/A"')
    TIMESTAMP=$(echo $HEAD | jq -r '.timestamp // "N/A"')
    HASH=$(echo $HEAD | jq -r '.hash // "N/A"')
    PROTOCOL=$(echo $HEAD | jq -r '.protocol // "N/A"')

    echo -e "  Block Height: ${GREEN}$LEVEL${NC}"
    echo -e "  Block Hash:   ${BLUE}${HASH:0:30}...${NC}"
    echo -e "  Timestamp:    $TIMESTAMP"
    echo -e "  Protocol:     ${PROTOCOL:0:10}..."
else
    echo -e "${RED}  ❌ Cannot connect to RPC${NC}"
fi

echo ""

# Get network connections
echo -e "${YELLOW}🌐 NETWORK STATUS:${NC}"
CONNECTIONS=$(rpc_get_connections)

if [ $? -eq 0 ] && [ -n "$CONNECTIONS" ]; then
    CONN_COUNT=$(echo "$CONNECTIONS" | jq 'length // 0' 2>/dev/null)

    if [ -n "$CONN_COUNT" ] && [ "$CONN_COUNT" != "null" ]; then
        echo -e "  Active Peers: ${GREEN}$CONN_COUNT${NC}"

        if [ "$CONN_COUNT" -gt 0 ]; then
            # Show top 5 peers
            echo -e "\n  ${BLUE}Connected Peers:${NC}"
            echo "$CONNECTIONS" | jq -r '.[:5] | .[] | "    • \(.id_point.addr) [\(.peer_id[0:8])...]"' 2>/dev/null || echo "    (peer details unavailable)"
        else
            echo -e "  ${YELLOW}⚠️  No active connections${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠️  Connection count unavailable${NC}"
    fi
else
    echo -e "${RED}  ❌ Cannot fetch network info${NC}"
fi

echo ""

# Get sync status from logs
echo -e "${YELLOW}🔄 SYNC STATUS:${NC}"
LAST_LOGS=$(docker logs --tail 10 $(get_container_name) 2>&1)
if echo "$LAST_LOGS" | grep -q "synchronisation status: synced"; then
    echo -e "  ${GREEN}✅ SYNCED${NC}"
elif echo "$LAST_LOGS" | grep -q "synchronizing"; then
    echo -e "  ${YELLOW}⏳ Synchronizing...${NC}"
    echo "$LAST_LOGS" | grep "synchronizing" | tail -1 | grep -o "current head is.*" | sed 's/^/  /'
elif echo "$LAST_LOGS" | grep -q "head is now"; then
    echo -e "  ${GREEN}✅ SYNCED${NC} - Processing real-time blocks"
    LATEST_BLOCK=$(echo "$LAST_LOGS" | grep "head is now" | tail -1 | sed 's/.*head is now//')
    echo -e "  Latest:$LATEST_BLOCK"
else
    echo -e "  ${BLUE}ℹ️  Node running${NC}"
fi

echo ""

# Get chain info
echo -e "${YELLOW}⛓️  CHAIN INFO:${NC}"
CHAIN_ID=$(rpc_get_chain_id)
if [ -n "$CHAIN_ID" ] && [ "$CHAIN_ID" != "null" ]; then
    echo -e "  Chain ID: ${BLUE}$CHAIN_ID${NC}"

    # Network name mapping
    if [ "$CHAIN_ID" == "NetXnHfVqm9iesp" ]; then
        echo -e "  Network:  ${CYAN}Ghostnet Testnet${NC}"
    fi
else
    echo -e "${RED}  ❌ Cannot fetch chain info${NC}"
fi

echo ""
echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"
echo -e "Commands:"
echo -e "  ${GREEN}npm run node:logs${NC}     - Watch real-time logs"
echo -e "  ${GREEN}npm run node:head${NC}     - Current block details"
echo -e "  ${GREEN}npm run node:peers${NC}    - List all peers"
echo -e "  ${GREEN}npm run monitor:watch${NC} - Auto-refresh this view"
echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"
