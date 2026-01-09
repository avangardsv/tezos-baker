#!/usr/bin/env bash
# Complete DAL setup from scratch
# Initializes, starts DAL node, and reconfigures baker

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    echo ""
    log_info "=== Complete DAL Setup ==="
    echo ""

    # Step 1: Initialize DAL
    log_info "Step 1/3: Initializing DAL configuration..."
    "$SCRIPT_DIR/dal-init.sh"

    echo ""

    # Step 2: Start DAL node
    log_info "Step 2/3: Starting DAL node..."
    "$SCRIPT_DIR/dal-start.sh"

    echo ""

    # Step 3: Reconfigure baker
    log_info "Step 3/3: Reconfiguring baker with DAL support..."
    "$SCRIPT_DIR/baker-enable-dal.sh"

    echo ""
    log_success "✅ DAL setup complete!"
    echo ""
    log_info "Verify DAL attestations:"
    log_info "  docker logs -f tezos-baker | grep 'with DAL'"
    echo ""
    log_info "Check status:"
    log_info "  npm run dal:verify"
}

main "$@"
