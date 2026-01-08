#!/usr/bin/env bash
# Start Tezos baker container
# Extracted from package.json for maintainability
# Includes preflight checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/health.sh"

# =============================================================================
# MAIN
# =============================================================================

main() {
    local container_name="${CONTAINER_PREFIX}-baker"
    
    # Preflight checks
    log_info "Running preflight checks..."
    if ! preflight_node_check; then
        log_error "Preflight checks failed. Cannot start baker."
        exit 1
    fi
    
    # Check if container already exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            log_warn "Baker container '$container_name' is already running"
            exit 0
        else
            log_info "Starting existing container '$container_name'"
            docker start "$container_name"
            log_success "Baker container started"
            exit 0
        fi
    fi
    
    log_info "Starting Tezos baker container..."
    
    docker run -d \
        --name "$container_name" \
        --network "container:${CONTAINER_PREFIX}-node" \
        -v "$PROJECT_ROOT/$DATA_DIR:/var/run/tezos/node" \
        -v "$PROJECT_ROOT/$DATA_DIR/.tezos-client:/home/tezos/.tezos-client" \
        --entrypoint "octez-baker-${PROTOCOL}" \
        "tezos/tezos:${OCTEZ_VERSION}" \
        run with local node /var/run/tezos/node \
        --without-dal \
        --liquidity-baking-toggle-vote pass \
        "${BAKER_ALIAS}"
    
    log_success "Baker container started"
    log_info "Check logs: npm run baker:logs"
    log_info "Check status: npm run stake:status"
}

main "$@"

