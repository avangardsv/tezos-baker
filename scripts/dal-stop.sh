#!/usr/bin/env bash
# Stop DAL node

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local container_name="${CONTAINER_PREFIX:-tezos}-dal-node"

    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_warn "DAL node container not found"
        exit 0
    fi

    log_info "Stopping DAL node..."
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true

    log_success "DAL node stopped and removed"
}

main "$@"
