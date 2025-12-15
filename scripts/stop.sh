#!/usr/bin/env bash

# Tezos Baker - One-Command Stop Script
# Gracefully stops all services

set -euo pipefail

echo "=== Stopping Tezos Baker ==="
echo ""

# Stop baker and endorser first
echo "Stopping baker and endorser..."
docker compose stop tezos-baker tezos-endorser 2>/dev/null || true

# Stop node
echo "Stopping node..."
docker compose stop tezos-node 2>/dev/null || true

# Optionally stop monitoring
if docker ps --format "{{.Names}}" | grep -q "prometheus\|grafana"; then
    echo "Stopping monitoring services..."
    docker compose --profile monitoring stop 2>/dev/null || true
fi

echo ""
echo "=== Services Stopped ==="
echo ""
echo "To start again: docker compose up -d"
echo ""

