#!/usr/bin/env bash
# Stop node with automatic log backup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# MAIN
# =============================================================================

main() {
    local container_name="${CONTAINER_PREFIX}-node"
    local log_dir="$PROJECT_ROOT/logs"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local log_file="$log_dir/node-$timestamp.log"
    
    # Create logs directory if it doesn't exist
    mkdir -p "$log_dir"
    
    # Check if container exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_info "Saving node logs to: $log_file"
        
        # Save logs (both stdout and stderr)
        docker logs "$container_name" > "$log_file" 2>&1
        
        # Get log file size for feedback
        local log_size=$(du -h "$log_file" | awk '{print $1}')
        log_success "Saved $log_size of logs"
        
        # Stop and remove container
        log_info "Stopping node container..."
        docker rm -f "$container_name" > /dev/null
        log_success "Node stopped"
    else
        log_info "Node container not running (nothing to stop)"
    fi
}

main "$@"
