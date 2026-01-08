#!/usr/bin/env bash
# Initialize Tezos node configuration
# Extracted from package.json for maintainability

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# MAIN
# =============================================================================

main() {
    log_info "Initializing Tezos node configuration..."
    
    # Create data directory
    mkdir -p "$PROJECT_ROOT/$DATA_DIR"
    
    # Run node config init
    docker run --rm \
        --entrypoint octez-node \
        -v "$PROJECT_ROOT/$DATA_DIR:/var/run/tezos/node" \
        "tezos/tezos:${OCTEZ_VERSION}" \
        config init \
        --network "${TEZOS_NETWORK}" \
        --history-mode "${HISTORY_MODE}" \
        --rpc-addr "0.0.0.0:${RPC_PORT}" \
        --net-addr "0.0.0.0:${P2P_PORT}" \
        --data-dir /var/run/tezos/node
    
    log_success "Node configuration initialized"
}

main "$@"

