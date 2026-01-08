#!/usr/bin/env bash
# Show comprehensive status

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    echo "=== Container Status ==="
    npm run status:containers
    echo ""
    echo "=== Node Health ==="
    npm run node:health || true
    echo ""
    echo "=== Staking Status ==="
    npm run stake:status || true
}

main "$@"

