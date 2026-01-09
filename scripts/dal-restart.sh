#!/usr/bin/env bash
# Restart DAL node

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local container_name="${CONTAINER_PREFIX:-tezos}-dal-node"

    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_info "Restarting DAL node..."
        docker start "$container_name" 2>/dev/null || docker restart "$container_name"
        log_success "DAL node restarted"
    else
        log_error "DAL node container not found"
        log_info "Start DAL first: npm run dal:start"
        exit 1
    fi
}

main "$@"
