#!/usr/bin/env bash

# Detailed sync status check

echo "=== Detailed Node Sync Status ==="
echo ""

# Check if container is running
if ! docker ps --format "{{.Names}}" | grep -q "tezos-node"; then
    echo "❌ Node container is not running"
    exit 1
fi

echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep tezos-node
echo ""

# Check bootstrapped status
echo "Bootstrapped Status:"
if docker exec tezos-node octez-client bootstrapped 2>&1 | grep -q "Bootstrapped"; then
    echo "✅ Node is bootstrapped"
    BOOTSTRAPPED=true
else
    echo "⏳ Node is still bootstrapping..."
    BOOTSTRAPPED=false
fi
echo ""

# Get current block level
echo "Blockchain Status:"
HEAD_LEVEL=$(docker exec tezos-node octez-client rpc get /chains/main/blocks/head/header 2>&1 | grep -o '"level":[0-9]*' | cut -d: -f2 || echo "unknown")
if [ "$HEAD_LEVEL" != "unknown" ]; then
    echo "  Current head level: $HEAD_LEVEL"
    
    # Try to get network level
    NETWORK_LEVEL=$(docker exec tezos-node octez-client rpc get /chains/main/blocks/head/header 2>&1 | grep -o '"level":[0-9]*' | cut -d: -f2 || echo "unknown")
    echo "  Network level: $NETWORK_LEVEL"
    
    if [ "$HEAD_LEVEL" = "$NETWORK_LEVEL" ] && [ "$BOOTSTRAPPED" = "true" ]; then
        echo ""
        echo "✅ Node is fully synchronized!"
    else
        echo ""
        echo "⏳ Node is still syncing..."
    fi
else
    echo "  ⚠️  Cannot get block level (node may still be starting)"
fi
echo ""

# Check recent logs for errors
echo "Recent Log Activity (last 10 lines):"
docker logs --tail 10 tezos-node 2>&1 | tail -10
echo ""

# Check for common issues
echo "Checking for common issues..."
if docker logs tezos-node 2>&1 | grep -qi "error\|fatal\|panic"; then
    echo "  ⚠️  Errors found in logs - check with: docker logs tezos-node"
else
    echo "  ✅ No obvious errors in logs"
fi



