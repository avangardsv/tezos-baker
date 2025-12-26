#!/usr/bin/env bash

# Fix and restart the node with correct command

set -euo pipefail

echo "=== Fixing Tezos Node ==="
echo ""

# Stop containers
echo "Stopping containers..."
docker compose down

# Rebuild with fixed command
echo "Rebuilding containers..."
docker compose build tezos-node

# Start node
echo "Starting node..."
docker compose up -d tezos-node

echo ""
echo "✅ Node restarted with fixed command"
echo ""
echo "Check status: ./scripts/status.sh"
echo "View logs: docker logs -f tezos-node"




