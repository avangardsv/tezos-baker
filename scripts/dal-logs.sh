#!/usr/bin/env bash
# View DAL node logs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"

docker logs -f "${CONTAINER_PREFIX:-tezos}-dal-node"
