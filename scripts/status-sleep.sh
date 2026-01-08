#!/usr/bin/env bash
# Get system sleep status (OS-specific)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/platform.sh"

main() {
    get_sleep_status
}

main "$@"

