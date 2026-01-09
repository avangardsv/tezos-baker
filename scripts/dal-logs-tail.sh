#!/usr/bin/env bash
# View last 50 lines of DAL node logs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"

docker logs --tail 50 "${CONTAINER_PREFIX:-tezos}-dal-node"
