#!/usr/bin/env bash
# Restart baker container

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local container_name="${CONTAINER_PREFIX}-baker"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_info "Restarting baker container..."
        docker start "$container_name" 2>/dev/null || docker restart "$container_name"
        log_success "Baker restarted"
    else
        log_error "Baker container not found"
        log_info "Start baker first: npm run baker:start"
        exit 1
    fi
}

main "$@"

