#!/usr/bin/env bash
# Reconfigure baker to use DAL node
# This stops the current baker and starts a new one with DAL support

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/health.sh"

main() {
    local baker_container="${CONTAINER_PREFIX}-baker"
    local dal_container="${CONTAINER_PREFIX}-dal-node"

    # Check if DAL node is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${dal_container}$"; then
        log_error "DAL node is not running"
        log_info "Start DAL node first: npm run dal:start"
        exit 1
    fi

    log_info "Reconfiguring baker to use DAL..."

    # Stop and remove existing baker
    if docker ps -a --format '{{.Names}}' | grep -q "^${baker_container}$"; then
        log_info "Stopping current baker..."
        docker stop "$baker_container" 2>/dev/null || true
        docker rm "$baker_container" 2>/dev/null || true
    fi

    # Start baker with DAL support
    log_info "Starting baker with DAL support..."

    docker run -d \
        --name "$baker_container" \
        --network "container:${CONTAINER_PREFIX}-node" \
        -v "$PWD/$DATA_DIR:/var/run/tezos/node" \
        -v "$PWD/$DATA_DIR/.tezos-client:/home/tezos/.tezos-client" \
        --entrypoint "octez-baker-${PROTOCOL}" \
        "tezos/tezos:${OCTEZ_VERSION}" \
        run with local node /var/run/tezos/node \
        --dal-node http://127.0.0.1:${DAL_RPC_PORT:-10732} \
        --liquidity-baking-toggle-vote pass \
        "${BAKER_ALIAS}"

    log_success "Baker reconfigured with DAL support!"
    log_info "Check logs: npm run baker:logs"
    log_info "DAL attestations will start appearing in logs"

    echo ""
    log_info "Monitor for DAL attestations:"
    log_info "  docker logs -f $baker_container | grep 'DAL'"
}

main "$@"
