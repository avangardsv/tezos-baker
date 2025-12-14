#!/usr/bin/env bash

# Tezos Baker - One-Command Setup Script
# Installs dependencies, imports snapshot (optional), and starts services
#
# Usage: ./setup.sh [network] [--skip-snapshot]
#   network: ghostnet (default) or mainnet
#   --skip-snapshot: Skip snapshot import and do full sync

set -euo pipefail

# Source logging library if available
if [ -f "$(dirname "$0")/scripts/lib/log.sh" ]; then
    source "$(dirname "$0")/scripts/lib/log.sh"
fi

# Configuration
NETWORK="${1:-ghostnet}"
SKIP_SNAPSHOT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-snapshot)
            SKIP_SNAPSHOT=true
            shift
            ;;
        ghostnet|mainnet)
            NETWORK="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=== Tezos Baker Setup ==="
echo "Network: $NETWORK"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
command -v podman >/dev/null 2>&1 || { echo "Error: podman is required but not installed"; exit 1; }
command -v podman-compose >/dev/null 2>&1 || { echo "Error: podman-compose is required but not installed. Install with: pip install podman-compose"; exit 1; }

# Create necessary directories
echo "Creating directories..."
mkdir -p data logs backups

# Set up environment
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "Please edit .env with your settings"
    else
        echo "Warning: .env.example not found, creating basic .env"
        cat > .env << EOF
TEZOS_NETWORK=$NETWORK
BAKER_ALIAS=alice
EOF
    fi
fi

# Update network in .env if needed
if grep -q "^TEZOS_NETWORK=" .env; then
    sed -i.bak "s/^TEZOS_NETWORK=.*/TEZOS_NETWORK=$NETWORK/" .env
else
    echo "TEZOS_NETWORK=$NETWORK" >> .env
fi

# Select config file based on network
if [ "$NETWORK" = "mainnet" ]; then
    CONFIG_FILE="config-mainnet.json"
else
    CONFIG_FILE="config-ghostnet.json"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found"
    exit 1
fi

# Start Podman services
echo "Starting Podman services..."
# podman-compose can use docker-compose.yml or specify with -f
if [ -f "podman-compose.yml" ]; then
    podman-compose -f podman-compose.yml up -d
elif [ -f "docker-compose.yml" ]; then
    podman-compose up -d
else
    echo "Error: No compose file found (podman-compose.yml or docker-compose.yml)"
    exit 1
fi

# Wait for node to be ready
echo "Waiting for node to start..."
sleep 10

# Import snapshot if requested
if [ "$SKIP_SNAPSHOT" = false ] && [ -f "scripts/import_snapshot.sh" ]; then
    echo ""
    read -p "Import snapshot for faster sync? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Importing snapshot..."
        ./scripts/import_snapshot.sh "$NETWORK" || echo "Snapshot import failed, continuing with full sync"
    fi
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Wait for node to sync: ./status.sh"
echo "2. Generate keys: podman exec tezos-node tezos-client gen keys alice"
echo "3. Fund your account (testnet faucet or transfer)"
echo "4. Register delegate: ./start.sh alice $NETWORK"
echo ""

