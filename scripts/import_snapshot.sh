#!/usr/bin/env bash

# Tezos Baker - Snapshot Import Script
# Downloads and imports a Tezos blockchain snapshot for faster node synchronization
#
# Usage: ./import_snapshot.sh [network]
#   network: ghostnet (default) or mainnet

set -euo pipefail

# Source logging library
source "$(dirname "$0")/lib/log.sh"

# Configuration
NETWORK="${1:-ghostnet}"
SNAPSHOT_URL_GHOSTNET="https://snapshots-tezos.giganode.io/ghostnet.full"
SNAPSHOT_URL_MAINNET="https://snapshots-tezos.giganode.io/mainnet.full" 
TEMP_DIR="/tmp"
CONTAINER_NAME="tezos-node"

# Initialize script logging
log_script_start "Import $NETWORK snapshot"

# Validate network parameter
validate_network() {
    case "$NETWORK" in
        "ghostnet"|"mainnet")
            log_step "VALIDATION" "SUCCESS" "Network '$NETWORK' is valid"
            ;;
        *)
            log_step "VALIDATION" "ERROR" "Invalid network '$NETWORK'. Use 'ghostnet' or 'mainnet'"
            exit 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log_step "PREREQUISITES" "START" "Checking required tools"
    
    local required_commands=("curl" "docker")
    validate_prerequisites "${required_commands[@]}"
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_step "PREREQUISITES" "ERROR" "Docker daemon is not running"
        exit 1
    fi
    
    # Check available disk space (require at least 10GB)
    local available_space
    available_space=$(df "$TEMP_DIR" | tail -1 | awk '{print $4}')
    local space_gb=$((available_space / 1024 / 1024))
    
    if [ "$space_gb" -lt 10 ]; then
        log_step "PREREQUISITES" "ERROR" "Insufficient disk space: ${space_gb}GB available, 10GB+ required"
        exit 1
    fi
    
    log_step "PREREQUISITES" "SUCCESS" "Available disk space: ${space_gb}GB"
}

# Download snapshot
download_snapshot() {
    local snapshot_url
    local snapshot_file="$TEMP_DIR/${NETWORK}.full"
    
    case "$NETWORK" in
        "ghostnet")
            snapshot_url="$SNAPSHOT_URL_GHOSTNET"
            ;;
        "mainnet")
            snapshot_url="$SNAPSHOT_URL_MAINNET"
            ;;
    esac
    
    log_step "SNAPSHOT_DOWNLOAD" "START" "Downloading $NETWORK snapshot from $snapshot_url"
    
    # Remove existing snapshot file if present
    if [ -f "$snapshot_file" ]; then
        log_step "SNAPSHOT_DOWNLOAD" "INFO" "Removing existing snapshot file"
        rm -f "$snapshot_file"
    fi
    
    # Download with progress and resume support
    if curl -L --retry 3 --retry-delay 10 -C - -o "$snapshot_file" "$snapshot_url"; then
        local file_size
        file_size=$(du -h "$snapshot_file" | cut -f1)
        log_step "SNAPSHOT_DOWNLOAD" "SUCCESS" "Downloaded $NETWORK snapshot ($file_size)"
        echo "$snapshot_file"
    else
        log_step "SNAPSHOT_DOWNLOAD" "ERROR" "Failed to download snapshot from $snapshot_url"
        rm -f "$snapshot_file"
        exit 1
    fi
}

# Check if container exists and is running
check_container() {
    log_step "CONTAINER_CHECK" "START" "Checking if $CONTAINER_NAME container exists"
    
    if ! docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_step "CONTAINER_CHECK" "ERROR" "Container '$CONTAINER_NAME' does not exist"
        log_step "CONTAINER_CHECK" "INFO" "Start the Tezos node first using docker compose"
        exit 1
    fi
    
    if ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_step "CONTAINER_CHECK" "WARNING" "Container '$CONTAINER_NAME' exists but is not running"
        log_step "CONTAINER_CHECK" "INFO" "Starting container..."
        
        if docker start "$CONTAINER_NAME"; then
            log_step "CONTAINER_CHECK" "SUCCESS" "Container started successfully"
        else
            log_step "CONTAINER_CHECK" "ERROR" "Failed to start container"
            exit 1
        fi
    else
        log_step "CONTAINER_CHECK" "SUCCESS" "Container '$CONTAINER_NAME' is running"
    fi
}

# Stop node before import (if running)
stop_node() {
    log_step "NODE_STOP" "START" "Stopping Tezos node for snapshot import"
    
    # Check if node process is running inside container
    if docker exec "$CONTAINER_NAME" pgrep tezos-node >/dev/null 2>&1; then
        log_step "NODE_STOP" "INFO" "Tezos node is running, stopping gracefully..."
        
        if docker exec "$CONTAINER_NAME" pkill -TERM tezos-node; then
            # Wait for graceful shutdown
            sleep 10
            log_step "NODE_STOP" "SUCCESS" "Tezos node stopped"
        else
            log_step "NODE_STOP" "WARNING" "Failed to stop node gracefully, may not be running"
        fi
    else
        log_step "NODE_STOP" "INFO" "Tezos node is not running"
    fi
}

# Import snapshot into node
import_snapshot() {
    local snapshot_file="$1"
    
    log_step "SNAPSHOT_IMPORT" "START" "Importing snapshot into Tezos node"
    
    # Import snapshot with progress monitoring
    if docker exec -i "$CONTAINER_NAME" tezos-node snapshot import --no-check /dev/stdin < "$snapshot_file" 2>&1 | \
       tee -a "$LOG_FILE" | grep -E "(Import|Imported|Error|error)"; then
        log_step "SNAPSHOT_IMPORT" "SUCCESS" "Snapshot imported successfully"
    else
        log_step "SNAPSHOT_IMPORT" "ERROR" "Failed to import snapshot"
        exit 1
    fi
}

# Cleanup temporary files
cleanup() {
    local snapshot_file="$TEMP_DIR/${NETWORK}.full"
    
    if [ -f "$snapshot_file" ]; then
        log_step "CLEANUP" "START" "Removing temporary snapshot file"
        rm -f "$snapshot_file"
        log_step "CLEANUP" "SUCCESS" "Cleanup completed"
    fi
}

# Verify import success
verify_import() {
    log_step "VERIFICATION" "START" "Verifying snapshot import"
    
    # Start node briefly to check if import was successful
    if docker exec "$CONTAINER_NAME" tezos-node run --network "$NETWORK" --data-dir /var/lib/tezos &
    then
        local node_pid=$!
        sleep 10
        
        # Check if node is responding
        if docker exec "$CONTAINER_NAME" tezos-client bootstrapped >/dev/null 2>&1; then
            log_step "VERIFICATION" "SUCCESS" "Node successfully loaded imported data"
        else
            log_step "VERIFICATION" "WARNING" "Node started but not yet synchronized"
        fi
        
        # Stop the test node
        docker exec "$CONTAINER_NAME" pkill tezos-node || true
        wait $node_pid 2>/dev/null || true
    else
        log_step "VERIFICATION" "ERROR" "Failed to start node after import"
        exit 1
    fi
}

# Main execution
main() {
    log_system_info
    
    validate_network
    check_prerequisites
    check_container
    stop_node
    
    local snapshot_file
    snapshot_file=$(download_snapshot)
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    import_snapshot "$snapshot_file"
    verify_import
    
    log_step "IMPORT_COMPLETE" "SUCCESS" "Snapshot import completed. You can now start the Tezos node."
    log_step "IMPORT_COMPLETE" "INFO" "Next step: docker compose -f docker/compose.${NETWORK}.yml up -d"
}

# Execute main function
main "$@"