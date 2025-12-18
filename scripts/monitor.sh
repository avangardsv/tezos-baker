#!/bin/bash

# Load environment variables safely
if [ -f .env ]; then
    set -a
    source <(grep -v '^#' .env | sed -e '/^\s*$/d' -e 's/^\([^=]*\)=\(.*\)$/\1="\2"/' -e 's/=""/=/g')
    set +a
fi

RPC_ENDPOINT="http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         TEZOS NODE MONITOR - GHOSTNET                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if node is running
if ! docker ps | grep -q "${CONTAINER_PREFIX:-tezos}-node"; then
    echo -e "${RED}❌ Node is not running${NC}"
    echo "Run: npm run node:start"
    exit 1
fi

echo -e "${GREEN}✅ Node is running${NC}"
echo ""

# Get current head
echo -e "${YELLOW}📊 BLOCKCHAIN STATUS:${NC}"
HEAD=$(curl -s $RPC_ENDPOINT/chains/main/blocks/head/header 2>/dev/null)

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
CONNECTIONS=$(curl -s $RPC_ENDPOINT/network/connections 2>/dev/null)

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

# Get sync status from logs (docker logs outputs to stderr, so capture it properly)
echo -e "${YELLOW}🔄 SYNC STATUS:${NC}"
LAST_LOGS=$(docker logs --tail 10 ${CONTAINER_PREFIX:-tezos}-node 2>&1)
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
CHAIN_ID=$(curl -s $RPC_ENDPOINT/chains/main/chain_id 2>/dev/null | tr -d '"')
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

