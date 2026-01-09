#!/usr/bin/env bash
# Initialize DAL node configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local data_dir="${DAL_DATA_DIR:-dal-data}"

    log_info "Initializing DAL node configuration..."

    # Create data directory
    mkdir -p "$data_dir"

    # Initialize DAL node config
    docker run --rm \
        --entrypoint octez-dal-node \
        -v "$PWD/$data_dir:/var/run/tezos/dal" \
        tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} \
        config init \
        --data-dir /var/run/tezos/dal \
        --endpoint http://127.0.0.1:${RPC_PORT:-8732} \
        --net-addr 0.0.0.0:${DAL_P2P_PORT:-11732}

    log_success "DAL node configuration initialized in $data_dir/"
    log_info "Next: npm run dal:start"
}

main "$@"
