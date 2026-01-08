#!/usr/bin/env bash
# Show container status

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    docker ps -a --filter "name=${CONTAINER_PREFIX}"
}

main "$@"

