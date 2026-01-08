#!/usr/bin/env bash
# Register delegate with preflight checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/health.sh"

main() {
    # Preflight checks
    if ! preflight_node_check; then
        log_error "Preflight checks failed. Cannot register delegate."
        exit 1
    fi
    
    log_info "Registering delegate: ${BAKER_ALIAS}"
    
    docker exec "${CONTAINER_PREFIX}-node" \
        octez-client \
        -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        register key "${BAKER_ALIAS}" as delegate
    
    log_success "Delegate registered: ${BAKER_ALIAS}"
    log_info "Check status: npm run stake:status"
}

main "$@"

