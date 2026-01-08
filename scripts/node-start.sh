#!/usr/bin/env bash
# Start Tezos node container
# Extracted from package.json for maintainability

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/health.sh"

# =============================================================================
# MAIN
# =============================================================================

main() {
    local container_name="${CONTAINER_PREFIX}-node"
    
    # Check if container already exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            log_warn "Node container '$container_name' is already running"
            exit 0
        else
            log_info "Starting existing container '$container_name'"
            docker start "$container_name"
            log_success "Node container started"
            exit 0
        fi
    fi
    
    log_info "Starting Tezos node container..."
    
    docker run -d \
        --name "$container_name" \
        --entrypoint octez-node \
        -v "$PROJECT_ROOT/$DATA_DIR:/var/run/tezos/node" \
        -p "${RPC_PORT}:${RPC_PORT}" \
        -p "${P2P_PORT}:${P2P_PORT}" \
        -p "${METRICS_PORT}:${METRICS_PORT}" \
        "tezos/tezos:${OCTEZ_VERSION}" \
        run \
        --network "${TEZOS_NETWORK}" \
        --data-dir /var/run/tezos/node \
        --metrics-addr "0.0.0.0:${METRICS_PORT}"
    
    log_success "Node container started"
    log_info "RPC: http://${RPC_ADDR}:${RPC_PORT}"
    log_info "Metrics: http://localhost:${METRICS_PORT}/metrics"
    log_info "Check status: npm run node:status"
}

main "$@"

