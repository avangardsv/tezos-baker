#!/usr/bin/env bash
# View live node logs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local container_name="${CONTAINER_PREFIX}-node"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        docker logs -f "$container_name"
    else
        log_error "Node container not found"
        log_info "Start node first: npm run node:start"
        exit 1
    fi
}

main "$@"

