#!/usr/bin/env bash
# Restart all services (consolidated restart behavior)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    log_info "Restarting all services..."
    
    # Restart node
    local node_container="${CONTAINER_PREFIX}-node"
    if docker ps -a --format '{{.Names}}' | grep -q "^${node_container}$"; then
        log_info "Restarting node..."
        docker restart "$node_container" || docker start "$node_container"
        log_success "Node restarted"
    else
        log_warn "Node container not found, skipping"
    fi
    
    # Wait for node to be ready
    log_info "Waiting for node to be ready..."
    sleep 5
    
    # Restart baker
    local baker_container="${CONTAINER_PREFIX}-baker"
    if docker ps -a --format '{{.Names}}' | grep -q "^${baker_container}$"; then
        log_info "Restarting baker..."
        docker restart "$baker_container" || docker start "$baker_container"
        log_success "Baker restarted"
    else
        log_warn "Baker container not found, skipping"
    fi
    
    # Start monitoring (if containers exist)
    local monitoring_containers=(
        "${CONTAINER_PREFIX}-prometheus"
        "${CONTAINER_PREFIX}-grafana"
        "${CONTAINER_PREFIX}-loki"
        "${CONTAINER_PREFIX}-promtail"
        "${CONTAINER_PREFIX}-node-exporter"
    )
    
    local found_monitoring=false
    for container in "${monitoring_containers[@]}"; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            found_monitoring=true
            break
        fi
    done
    
    if [ "$found_monitoring" = true ]; then
        log_info "Starting monitoring services..."
        for container in "${monitoring_containers[@]}"; do
            if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
                docker start "$container" 2>/dev/null || true
            fi
        done
        log_success "Monitoring services started"
    fi
    
    echo ""
    log_success "✅ All services restarted!"
    log_info "Check status: npm run status:all"
}

main "$@"

