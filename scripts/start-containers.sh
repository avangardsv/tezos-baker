#!/usr/bin/env bash

# Quick script to start containers and check status

set -euo pipefail

echo "=== Starting Tezos Containers ==="
echo ""

# Check if podman-compose is available
if ! command -v podman-compose >/dev/null 2>&1; then
    if [ -f "$HOME/Library/Python/3.9/bin/podman-compose" ]; then
        PODMAN_COMPOSE="$HOME/Library/Python/3.9/bin/podman-compose"
    else
        echo "Error: podman-compose not found"
        echo "Install with: pip3 install podman-compose"
        exit 1
    fi
else
    PODMAN_COMPOSE="podman-compose"
fi

# Use docker-compose.yml if it exists (symlink), otherwise podman-compose.yml
if [ -f "docker-compose.yml" ]; then
    COMPOSE_FILE="docker-compose.yml"
elif [ -f "podman-compose.yml" ]; then
    COMPOSE_FILE="podman-compose.yml"
else
    echo "Error: No compose file found"
    exit 1
fi

echo "Using compose file: $COMPOSE_FILE"
echo ""

# Start containers
echo "Starting containers..."
$PODMAN_COMPOSE -f "$COMPOSE_FILE" up -d

echo ""
echo "Waiting 5 seconds for containers to start..."
sleep 5

echo ""
echo "=== Container Status ==="
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== Checking for stopped containers ==="
STOPPED=$(podman ps -a --format "{{.Names}}\t{{.Status}}" | grep -E "tezos" | grep -v "Up" || true)
if [ -n "$STOPPED" ]; then
    echo "Some containers are stopped:"
    echo "$STOPPED"
    echo ""
    echo "Check logs with: podman logs <container-name>"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Check status: ./scripts/status.sh"
echo "2. View logs: podman logs -f tezos-node"
echo "3. Wait for sync (this takes 1-3 hours)"

