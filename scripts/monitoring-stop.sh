#!/usr/bin/env bash
# Stop monitoring services

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local containers=(
        "${CONTAINER_PREFIX}-prometheus"
        "${CONTAINER_PREFIX}-grafana"
        "${CONTAINER_PREFIX}-loki"
        "${CONTAINER_PREFIX}-promtail"
        "${CONTAINER_PREFIX}-node-exporter"
    )
    
    local stopped=0
    
    for container in "${containers[@]}"; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            log_info "Stopping $container..."
            docker stop "$container" 2>/dev/null && stopped=$((stopped + 1)) || true
        fi
    done
    
    if [ $stopped -gt 0 ]; then
        log_success "Stopped $stopped monitoring service(s)"
    else
        log_info "No monitoring services running"
    fi
}

main "$@"

