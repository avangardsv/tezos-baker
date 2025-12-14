#!/usr/bin/env bash

# Quick script to check container logs

echo "=== Tezos Node Logs (last 50 lines) ==="
podman logs --tail 50 tezos-node 2>&1 || echo "No logs available"

echo ""
echo "=== Tezos Baker Logs (last 30 lines) ==="
podman logs --tail 30 tezos-baker 2>&1 || echo "No logs available"

echo ""
echo "=== Tezos Endorser Logs (last 30 lines) ==="
podman logs --tail 30 tezos-endorser 2>&1 || echo "No logs available"

echo ""
echo "=== All Stopped Containers ==="
podman ps -a --format "table {{.Names}}\t{{.Status}}\t{{.ExitCode}}" | grep tezos

