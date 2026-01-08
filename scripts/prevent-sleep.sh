#!/usr/bin/env bash
# Prevent system sleep (OS-specific)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/platform.sh"

main() {
    prevent_sleep
}

main "$@"

