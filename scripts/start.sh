#!/usr/bin/env bash

# Tezos Baker - One-Command Start Script
# Registers delegate and starts baker/endorser
#
# Usage: ./start.sh <account_alias> [network]
#   account_alias: Name of the account to register and start
#   network: ghostnet (default) or mainnet

set -euo pipefail

# Source logging library if available
if [ -f "$(dirname "$0")/scripts/lib/log.sh" ]; then
    source "$(dirname "$0")/scripts/lib/log.sh"
fi

# Configuration
ACCOUNT_ALIAS="${1:-}"
NETWORK="${2:-ghostnet}"

if [ -z "$ACCOUNT_ALIAS" ]; then
    echo "Usage: $0 <account_alias> [network]"
    echo "Example: $0 alice ghostnet"
    exit 1
fi

echo "=== Starting Tezos Baker ==="
echo "Account: $ACCOUNT_ALIAS"
echo "Network: $NETWORK"
echo ""

# Check if node is running
if ! docker ps --format "{{.Names}}" | grep -q "tezos-node"; then
    echo "Error: Tezos node is not running"
    echo "Start it with: docker-compose up -d"
    exit 1
fi

# Check if node is synced
echo "Checking node sync status..."
if ! docker exec tezos-node tezos-client bootstrapped >/dev/null 2>&1; then
    echo "Warning: Node is not fully synced. Continue anyway? (y/n)"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Register delegate if script exists
if [ -f "scripts/register_delegate.sh" ]; then
    echo "Registering delegate..."
    ./scripts/register_delegate.sh "$ACCOUNT_ALIAS" "$NETWORK" || {
        echo "Warning: Delegate registration failed or already registered"
    }
fi

# Start baker/endorser if script exists
if [ -f "scripts/start_baker.sh" ]; then
    echo "Starting baker and endorser..."
    ./scripts/start_baker.sh "$ACCOUNT_ALIAS" "$NETWORK"
else
    # Fallback: use docker-compose
    echo "Starting baker and endorser via docker-compose..."
    docker-compose up -d tezos-baker tezos-endorser
fi

echo ""
echo "=== Baker Started ==="
echo ""
echo "Check status: ./status.sh"
echo "View logs: docker logs -f tezos-baker"
echo ""

