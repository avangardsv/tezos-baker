#!/usr/bin/env bash

# Quick script to start containers and check status

set -euo pipefail

echo "=== Starting Tezos Containers ==="
echo ""

# Check if docker compose is available
if ! command -v docker compose >/dev/null 2>&1; then
    if [ -f "$HOME/Library/Python/3.9/bin/docker compose" ]; then
        PODMAN_COMPOSE="$HOME/Library/Python/3.9/bin/docker compose"
    else
        echo "Error: docker compose not found"
        echo "Install with: pip3 install docker compose"
        exit 1
    fi
else
    PODMAN_COMPOSE="docker compose"
fi

# Use docker-compose.yml if it exists (symlink), otherwise docker compose.yml
if [ -f "docker-compose.yml" ]; then
    COMPOSE_FILE="docker-compose.yml"
elif [ -f "docker compose.yml" ]; then
    COMPOSE_FILE="docker compose.yml"
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
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== Checking for stopped containers ==="
STOPPED=$(docker ps -a --format "{{.Names}}\t{{.Status}}" | grep -E "tezos" | grep -v "Up" || true)
if [ -n "$STOPPED" ]; then
    echo "Some containers are stopped:"
    echo "$STOPPED"
    echo ""
    echo "Check logs with: docker logs <container-name>"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Check status: ./scripts/status.sh"
echo "2. View logs: docker logs -f tezos-node"
echo "3. Wait for sync (this takes 1-3 hours)"




