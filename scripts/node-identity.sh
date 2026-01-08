#!/usr/bin/env bash
# Generate node identity
# Extracted from package.json for maintainability

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# MAIN
# =============================================================================

main() {
    log_info "Generating node identity..."
    
    docker run --rm \
        --entrypoint octez-node \
        -v "$PROJECT_ROOT/$DATA_DIR:/var/run/tezos/node" \
        "tezos/tezos:${OCTEZ_VERSION}" \
        identity generate \
        --data-dir /var/run/tezos/node
    
    log_success "Node identity generated"
}

main "$@"

