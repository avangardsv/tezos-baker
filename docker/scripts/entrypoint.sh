#!/bin/bash
set -euo pipefail

# Tezos Node Entrypoint Script
# Handles initialization and startup of Tezos components

# Source configuration
TEZOS_NETWORK=${TEZOS_NETWORK:-ghostnet}
LOG_LEVEL=${LOG_LEVEL:-INFO}
HISTORY_MODE=${HISTORY_MODE:-rolling}
ENABLE_RPC=${ENABLE_RPC:-true}
RPC_ADDR=${RPC_ADDR:-0.0.0.0}
MAX_CONNECTIONS=${MAX_CONNECTIONS:-50}
ENABLE_METRICS=${ENABLE_METRICS:-true}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Tezos ${TEZOS_NETWORK} setup..."

# Initialize data directory permissions
if [ "$(id -u)" = "0" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running as root, fixing permissions..."
    chown -R ${PUID:-1000}:${PGID:-1000} /var/lib/tezos /var/log/tezos
    exec gosu ${PUID:-1000}:${PGID:-1000} "$0" "$@"
fi

# Function to initialize node configuration
init_node_config() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Initializing node configuration..."
    
    local config_file="/var/lib/tezos/config.json"
    local data_dir="/var/lib/tezos"
    
    # Initialize node if not already done
    if [ ! -f "$config_file" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating initial node configuration..."
        
        tezos-node config init \
            --data-dir="$data_dir" \
            --network="$TEZOS_NETWORK" \
            --history-mode="$HISTORY_MODE" \
            --net-addr="0.0.0.0:9732" \
            --rpc-addr="$RPC_ADDR:8732" \
            --log-output="/var/log/tezos/node.log"
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Node configuration created"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Using existing node configuration"
    fi
    
    # Update configuration with current settings
    if command -v jq >/dev/null 2>&1 && [ -f "$config_file" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Updating node configuration..."
        
        jq --arg network "$TEZOS_NETWORK" \
           --arg history "$HISTORY_MODE" \
           --arg rpc_addr "$RPC_ADDR:8732" \
           --arg max_conn "$MAX_CONNECTIONS" \
           '.network = $network | 
            .["history-mode"] = $history | 
            .rpc.["listen-addrs"] = [$rpc_addr] |
            .p2p.limits.["max-connections"] = ($max_conn | tonumber)' \
           "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
    fi
}

# Function to generate node identity
generate_identity() {
    local identity_file="/var/lib/tezos/identity.json"
    
    if [ ! -f "$identity_file" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating node identity..."
        tezos-node identity generate --data-dir="/var/lib/tezos"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Node identity generated"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Using existing node identity"
    fi
}

# Function to wait for node readiness
wait_for_node() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for node to be ready..."
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if tezos-client --endpoint "http://127.0.0.1:8732" rpc get /chains/main/blocks/head/header >/dev/null 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Node is ready!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Node not ready yet, attempt $attempt/$max_attempts..."
        sleep 5
    done
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Node failed to become ready within $((max_attempts * 5)) seconds"
    return 1
}

# Function to start Tezos node
start_node() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Tezos node on $TEZOS_NETWORK..."
    
    # Build node command arguments
    local node_args=(
        "--data-dir=/var/lib/tezos"
        "--config-file=/var/lib/tezos/config.json"
        "--log-output=/var/log/tezos/node.log"
    )
    
    # Add RPC configuration if enabled
    if [ "$ENABLE_RPC" = "true" ]; then
        node_args+=(
            "--rpc-addr=$RPC_ADDR:8732"
        )
    fi
    
    # Add metrics configuration if enabled
    if [ "$ENABLE_METRICS" = "true" ]; then
        node_args+=(
            "--metrics-addr=0.0.0.0:9095"
        )
    fi
    
    # Add custom arguments if provided
    if [ -n "${OCTEZ_NODE_ARGS:-}" ]; then
        # shellcheck disable=SC2086
        node_args+=($OCTEZ_NODE_ARGS)
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Node command: tezos-node run ${node_args[*]}"
    
    # Start the node
    exec tezos-node run "${node_args[@]}"
}

# Function to start baker
start_baker() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Tezos baker..."
    
    local baker_alias="${BAKER_ALIAS:-baker}"
    local node_rpc="${NODE_RPC_URL:-http://localhost:8732}"
    
    # Wait for node to be ready
    wait_for_node
    
    # Check if baker key exists
    if ! tezos-client --endpoint "$node_rpc" show address "$baker_alias" >/dev/null 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Baker key '$baker_alias' not found"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generate keys with: tezos-client gen keys $baker_alias"
        exit 1
    fi
    
    # Build baker command arguments
    local baker_args=()
    
    # Add custom arguments if provided
    if [ -n "${OCTEZ_BAKER_ARGS:-}" ]; then
        # shellcheck disable=SC2086
        baker_args+=($OCTEZ_BAKER_ARGS)
    fi
    
    # Configure signer based on environment
    if [ "${USE_LEDGER:-false}" = "true" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Using Ledger hardware signer"
        baker_args+=("--ledger")
    elif [ "${REMOTE_SIGNER:-false}" = "true" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Using remote signer at ${REMOTE_SIGNER_URL:-http://localhost:6732}"
        exec tezos-baker-alpha run remote signer "${REMOTE_SIGNER_URL:-http://localhost:6732}" for "$baker_alias" "${baker_args[@]}"
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Baker command: tezos-baker-alpha run with local node /var/lib/tezos $baker_alias ${baker_args[*]}"
    
    # Start the baker
    exec tezos-baker-alpha run with local node /var/lib/tezos "$baker_alias" "${baker_args[@]}"
}

# Function to start endorser
start_endorser() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Tezos endorser..."
    
    local baker_alias="${BAKER_ALIAS:-baker}"
    local node_rpc="${NODE_RPC_URL:-http://localhost:8732}"
    
    # Wait for node to be ready
    wait_for_node
    
    # Check if endorser key exists
    if ! tezos-client --endpoint "$node_rpc" show address "$baker_alias" >/dev/null 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Endorser key '$baker_alias' not found"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generate keys with: tezos-client gen keys $baker_alias"
        exit 1
    fi
    
    # Build endorser command arguments
    local endorser_args=()
    
    # Add custom arguments if provided
    if [ -n "${OCTEZ_ENDORSER_ARGS:-}" ]; then
        # shellcheck disable=SC2086
        endorser_args+=($OCTEZ_ENDORSER_ARGS)
    fi
    
    # Configure signer based on environment
    if [ "${USE_LEDGER:-false}" = "true" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Using Ledger hardware signer"
        endorser_args+=("--ledger")
    elif [ "${REMOTE_SIGNER:-false}" = "true" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Using remote signer at ${REMOTE_SIGNER_URL:-http://localhost:6732}"
        exec tezos-endorser-alpha run remote signer "${REMOTE_SIGNER_URL:-http://localhost:6732}" for "$baker_alias" "${endorser_args[@]}"
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Endorser command: tezos-endorser-alpha run $baker_alias ${endorser_args[*]}"
    
    # Start the endorser
    exec tezos-endorser-alpha run "$baker_alias" "${endorser_args[@]}"
}

# Function to start signer
start_signer() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Tezos signer..."
    
    if [ "${USE_LEDGER:-false}" = "true" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting HTTP signer with Ledger support"
        exec tezos-signer launch http signer --address 0.0.0.0 --port 6732
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting socket signer"
        exec tezos-signer launch socket signer --path /var/lib/tezos/signer.sock
    fi
}

# Main execution
main() {
    # Create log directory
    mkdir -p /var/log/tezos
    
    # Set log file permissions
    touch /var/log/tezos/node.log /var/log/tezos/baker.log /var/log/tezos/endorser.log
    chmod 644 /var/log/tezos/*.log
    
    # Initialize based on command
    case "${1:-node}" in
        "node")
            init_node_config
            generate_identity
            start_node
            ;;
        "baker")
            start_baker
            ;;
        "endorser")
            start_endorser
            ;;
        "signer")
            start_signer
            ;;
        *)
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Unknown command: $1"
            echo "Available commands: node, baker, endorser, signer"
            exit 1
            ;;
    esac
}

# Trap signals for graceful shutdown
trap 'echo "[$(date '+%Y-%m-%d %H:%M:%S')] Received shutdown signal, stopping..."; exit 0' SIGTERM SIGINT

# Execute main function
main "$@"