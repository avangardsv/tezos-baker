#!/usr/bin/env bash
# Centralized environment loading with validation and defaults
# Source this file in scripts: source "$(dirname "$0")/lib/env.sh"

set -euo pipefail

# =============================================================================
# ENVIRONMENT LOADING
# =============================================================================

load_env() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(cd "$script_dir/../.." && pwd)"
    
    # Load .env if it exists
    if [ -f "$project_root/.env" ]; then
        set -a
        # Source .env, handling comments and empty lines
        source <(
            grep -v '^#' "$project_root/.env" | \
            sed -e '/^\s*$/d' \
                -e "s/^\([^=]*\)=\(.*\)$/\1=\"\2\"/" \
                -e 's/=""/=/g'
        )
        set +a
    fi
    
    # Set defaults for required variables
    export DATA_DIR="${DATA_DIR:-data}"
    export BACKUP_DIR="${BACKUP_DIR:-backups}"
    export CONTAINER_PREFIX="${CONTAINER_PREFIX:-tezos}"
    export TEZOS_NETWORK="${TEZOS_NETWORK:-ghostnet}"
    export OCTEZ_VERSION="${OCTEZ_VERSION:-octez-v23.1}"
    export RPC_PORT="${RPC_PORT:-8732}"
    export P2P_PORT="${P2P_PORT:-9732}"
    export METRICS_PORT="${METRICS_PORT:-9095}"
    export RPC_ADDR="${RPC_ADDR:-127.0.0.1}"
    export HISTORY_MODE="${HISTORY_MODE:-rolling}"
    export BAKER_ALIAS="${BAKER_ALIAS:-alice}"
    export PROTOCOL="${PROTOCOL:-PtSeouLo}"
    
    # Export project root for use in scripts
    export PROJECT_ROOT="$project_root"
}

# =============================================================================
# VALIDATION
# =============================================================================

validate_env() {
    local errors=0
    
    # Check if .env exists (optional but recommended)
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        echo "⚠️  Warning: .env file not found. Using defaults." >&2
        echo "   Copy .env.example to .env for customization." >&2
    fi
    
    # Validate required directories exist
    if [ ! -d "$PROJECT_ROOT/$DATA_DIR" ]; then
        echo "⚠️  Warning: Data directory '$DATA_DIR' does not exist." >&2
        echo "   Run 'npm run node:init' first." >&2
    fi
    
    return 0
}

# =============================================================================
# DEPENDENCY CHECKS
# =============================================================================

check_dependencies() {
    local missing=()
    local deps=("docker" "jq" "curl")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    # Optional dependencies (warn but don't fail)
    if ! command -v "wget" >/dev/null 2>&1; then
        echo "⚠️  Warning: 'wget' not found. Snapshot download may fail." >&2
    fi
    
    if ! command -v "bc" >/dev/null 2>&1; then
        echo "⚠️  Warning: 'bc' not found. Some calculations may fail." >&2
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "❌ Error: Missing required dependencies: ${missing[*]}" >&2
        echo "   Please install: ${missing[*]}" >&2
        return 1
    fi
    
    return 0
}

# =============================================================================
# AUTO-LOAD ON SOURCE
# =============================================================================

# Load environment when script is sourced
load_env
validate_env

