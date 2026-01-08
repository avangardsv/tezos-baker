#!/usr/bin/env bash
# Create Tezos account with preflight checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/health.sh"

# =============================================================================
# MAIN
# =============================================================================

main() {
    # Preflight checks
    if ! preflight_node_check; then
        log_error "Preflight checks failed. Cannot create account."
        exit 1
    fi
    
    log_info "Creating account: ${BAKER_ALIAS}"
    
    docker exec "${CONTAINER_PREFIX}-node" \
        octez-client \
        -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        gen keys "${BAKER_ALIAS}"
    
    log_success "Account created: ${BAKER_ALIAS}"
    log_info "Show address: npm run account:show"
    log_info "Check balance: npm run account:balance"
}

main "$@"

