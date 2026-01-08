#!/usr/bin/env bash
# Get account balance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/health.sh"

main() {
    if ! check_node_container; then
        exit 1
    fi
    
    docker exec "${CONTAINER_PREFIX}-node" \
        octez-client \
        -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        get balance for "${BAKER_ALIAS}"
}

main "$@"

