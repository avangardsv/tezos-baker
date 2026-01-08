#!/usr/bin/env bash
# Hard restart node and baker

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local node_container="${CONTAINER_PREFIX}-node"
    local baker_container="${CONTAINER_PREFIX}-baker"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${node_container}$"; then
        log_info "Restarting node container..."
        docker restart "$node_container"
        log_success "Node restarted"
        
        log_info "Waiting for node to be ready..."
        sleep 5
        
        if docker ps -a --format '{{.Names}}' | grep -q "^${baker_container}$"; then
            log_info "Starting baker container..."
            docker start "$baker_container" 2>/dev/null || docker restart "$baker_container"
            log_success "Baker restarted"
        else
            log_warn "Baker container not found, skipping"
        fi
        
        log_success "Node and baker restarted"
    else
        log_error "Node container not found"
        log_info "Start node first: npm run node:start"
        exit 1
    fi
}

main "$@"

