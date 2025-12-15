#!/usr/bin/env bash

# Tezos Baker - One-Command Status Script
# Checks sync, baker health, and endorser health

set -euo pipefail

NETWORK="${1:-ghostnet}"

echo "=== Tezos Baker Status ==="
echo "Network: $NETWORK"
echo ""

# Check Docker services
echo "Docker Services:"
if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "tezos|prometheus|grafana"; then
    echo ""
else
    echo "No Tezos services running"
    echo ""
fi

# Check node sync
echo "Node Sync Status:"
if docker ps --format "{{.Names}}" | grep -q "tezos-node"; then
    if docker exec tezos-node octez-client bootstrapped >/dev/null 2>&1; then
        echo "✓ Node is bootstrapped and synchronized"

        # Get head level
        if HEAD=$(docker exec tezos-node octez-client rpc get /chains/main/blocks/head/header 2>/dev/null | grep -o '"level":[0-9]*' | cut -d: -f2); then
            echo "  Current level: $HEAD"
        fi
    else
        echo "✗ Node is not synchronized (still syncing...)"
        echo "  Check progress: ./scripts/check-sync-detail.sh"
        echo "  View logs: docker logs -f tezos-node"
    fi
    
    # Use check_sync script if available
    if [ -f "scripts/check_sync.sh" ]; then
        echo ""
        ./scripts/check_sync.sh "$NETWORK" 2>/dev/null || true
    fi
else
    echo "✗ Node container not running"
fi

echo ""

# Check baker process
echo "Baker Status:"
if docker ps --format "{{.Names}}" | grep -q "tezos-baker"; then
    if docker exec tezos-baker pgrep -f "octez-baker" >/dev/null 2>&1; then
        echo "✓ Baker process is running"
    else
        echo "✗ Baker process not running"
    fi
else
    echo "✗ Baker container not running"
fi

echo ""

# Check endorser process
echo "Endorser Status:"
if docker ps --format "{{.Names}}" | grep -q "tezos-endorser"; then
    if docker exec tezos-endorser pgrep -f "octez-endorser" >/dev/null 2>&1; then
        echo "✓ Endorser process is running"
    else
        echo "✗ Endorser process not running"
    fi
else
    echo "✗ Endorser container not running"
fi

echo ""

# Check monitoring (if enabled)
if docker ps --format "{{.Names}}" | grep -q "prometheus\|grafana"; then
    echo "Monitoring:"
    if docker ps --format "{{.Names}}" | grep -q "prometheus"; then
        echo "  ✓ Prometheus running"
    fi
    if docker ps --format "{{.Names}}" | grep -q "grafana"; then
        echo "  ✓ Grafana running (http://localhost:3000)"
    fi
    echo ""
fi

echo "=== Status Check Complete ==="
echo ""

