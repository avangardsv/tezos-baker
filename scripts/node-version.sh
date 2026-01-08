#!/usr/bin/env bash
# Set node version file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    log_info "Setting node version file..."
    
    docker run --rm \
        --entrypoint sh \
        -v "$PROJECT_ROOT/$DATA_DIR:/var/run/tezos/node" \
        "tezos/tezos:${OCTEZ_VERSION}" \
        -c 'echo "{\"version\": \"3.2\"}" > /var/run/tezos/node/version.json'
    
    log_success "Version file set"
}

main "$@"

