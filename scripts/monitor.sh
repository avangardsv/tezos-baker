#!/usr/bin/env bash

# Simple monitoring script for macOS (watch alternative)
# Refreshes status every 30 seconds

NETWORK="${1:-ghostnet}"

while true; do
    clear
    echo "=== Tezos Baker Monitor (Press Ctrl+C to stop) ==="
    echo "Last updated: $(date)"
    echo ""
    ./scripts/status.sh "$NETWORK"
    echo ""
    echo "Refreshing in 30 seconds..."
    sleep 30
done

