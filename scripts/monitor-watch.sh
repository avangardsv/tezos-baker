#!/usr/bin/env bash

# Auto-refresh monitor script (works on macOS without watch command)

echo "Starting monitor... Press Ctrl+C to exit"
echo ""

while true; do
    ./scripts/monitor.sh
    echo ""
    echo "Refreshing in 10 seconds... (Ctrl+C to exit)"
    sleep 10
done
