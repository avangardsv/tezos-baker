#!/usr/bin/env bash
# View last 50 lines of baker logs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local container_name="${CONTAINER_PREFIX}-baker"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        docker logs --tail 50 "$container_name"
    else
        log_error "Baker container not found"
        log_info "Start baker first: npm run baker:start"
        exit 1
    fi
}

main "$@"

