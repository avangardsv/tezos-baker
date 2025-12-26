#!/usr/bin/env bash

# Show next steps after node is running

echo "=== Tezos Baker - Next Steps ==="
echo ""

# Check node status
if docker ps --format "{{.Names}}" | grep -q "tezos-node"; then
    echo "✅ Node container is running"
    
    # Check if node is responding
    if docker exec tezos-node octez-client bootstrapped >/dev/null 2>&1; then
        echo "✅ Node is synchronized!"
        echo ""
        echo "🎉 Ready to proceed with:"
        echo "  1. Generate keys: docker exec tezos-node octez-client gen keys alice"
        echo "  2. Fund from faucet: https://faucet.ghostnet.teztnets.xyz/"
        echo "  3. Start baking: ./scripts/start.sh alice ghostnet"
    else
        echo "⏳ Node is still syncing..."
        echo ""
        echo "📊 Monitor sync progress:"
        echo "  ./scripts/check-sync-detail.sh"
        echo "  docker logs -f tezos-node"
        echo ""
        echo "⏱️  Expected sync time: 1-3 hours (with snapshot) or 6-12 hours (full sync)"
        echo ""
        echo "Once synchronized, you'll see:"
        echo "  ✓ Node is bootstrapped and synchronized"
    fi
else
    echo "❌ Node container is not running"
    echo "Start it with: docker compose up -d tezos-node"
fi

echo ""
echo "=== Useful Commands ==="
echo "  ./scripts/status.sh              - Quick status check"
echo "  ./scripts/monitor.sh             - Continuous monitoring"
echo "  ./scripts/check-sync-detail.sh   - Detailed sync info"
echo "  docker logs -f tezos-node        - View live logs"




