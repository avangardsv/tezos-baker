#!/usr/bin/env bash
# Start DAL node

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local container_name="${CONTAINER_PREFIX:-tezos}-dal-node"
    local data_dir="${DAL_DATA_DIR:-dal-data}"
    local node_container="${CONTAINER_PREFIX:-tezos}-node"

    # Check if container already exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_error "DAL node container already exists"
        log_info "Use: npm run dal:restart to restart it"
        exit 1
    fi

    # Get baker's public key hash
    log_info "Retrieving baker's public key hash..."
    local baker_pkh=$(docker exec "$node_container" octez-client -d /var/run/tezos/node/.tezos-client --endpoint http://127.0.0.1:${RPC_PORT:-8732} show address "${BAKER_ALIAS:-alice}" 2>/dev/null | grep "Hash:" | awk '{print $2}')

    if [ -z "$baker_pkh" ]; then
        log_error "Could not retrieve baker's public key hash"
        log_info "Ensure baker account exists: npm run account:show"
        exit 1
    fi

    log_info "Baker address: $baker_pkh"
    log_info "Starting DAL node..."

    docker run -d \
        --name "$container_name" \
        --network container:${CONTAINER_PREFIX:-tezos}-node \
        -v "$PWD/$data_dir:/var/run/tezos/dal" \
        --entrypoint octez-dal-node \
        tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} \
        run \
        --data-dir /var/run/tezos/dal \
        --rpc-addr 0.0.0.0:${DAL_RPC_PORT:-10732} \
        --endpoint http://127.0.0.1:${RPC_PORT:-8732} \
        --attester-profiles "$baker_pkh"

    log_success "DAL node started"
    log_info "Check logs: npm run dal:logs"
    log_info "Check status: docker ps --filter name=${container_name}"
}

main "$@"
