#!/usr/bin/env bash
# Start monitoring services

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
    
    local started=0
    local not_found=0
    
    for container in "${containers[@]}"; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            log_info "Starting $container..."
            docker start "$container" 2>/dev/null && started=$((started + 1)) || true
        else
            not_found=$((not_found + 1))
        fi
    done
    
    if [ $started -gt 0 ]; then
        log_success "Started $started monitoring service(s)"
    fi
    
    if [ $not_found -eq ${#containers[@]} ]; then
        log_warn "No monitoring containers found"
        log_info "Monitoring stack may not be set up"
    fi
}

main "$@"

