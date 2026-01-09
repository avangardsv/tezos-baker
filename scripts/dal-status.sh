#!/usr/bin/env bash
# Show DAL node status and health

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local dal_container="${CONTAINER_PREFIX:-tezos}-dal-node"

    echo ""
    log_info "=== DAL Node Status ==="
    echo ""

    # Container status
    if docker ps -a --format '{{.Names}}\t{{.Status}}' | grep "^${dal_container}"; then
        echo ""
    else
        log_error "DAL node container not found"
        log_info "Start DAL: npm run dal:start"
        exit 1
    fi

    # Recent activity
    echo ""
    log_info "Recent DAL Activity (last 10 lines):"
    docker logs --tail 10 "$dal_container" 2>&1 | sed 's/^/  /'

    # P2P connections
    echo ""
    local connections=$(docker logs --tail 50 "$dal_container" 2>&1 | grep -c "New_connection" || echo "0")
    log_info "DAL P2P Connections: $connections bootstrap peers"

    # Finalized blocks
    echo ""
    local finalized=$(docker logs --since 5m "$dal_container" 2>&1 | grep -c "Finalized block" || echo "0")
    log_info "Finalized blocks (last 5min): $finalized"

    echo ""
}

main "$@"
