#!/usr/bin/env bash

# Tezos Baker - Node Data Cleanup Script
# Safely removes Tezos node data for fresh sync or troubleshooting
#
# Usage: ./clean_node_data.sh [--force] [--keep-identity] [--keep-config]
#   --force: Skip confirmation prompts
#   --keep-identity: Preserve node identity files
#   --keep-config: Preserve configuration files

set -euo pipefail

# Source logging library
source "$(dirname "$0")/lib/log.sh"

# Configuration
CONTAINER_NAME="tezos-node"
FORCE_CLEANUP=false
KEEP_IDENTITY=false
KEEP_CONFIG=false

# Initialize script logging
log_script_start "Clean Tezos node data"

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE_CLEANUP=true
                shift
                ;;
            --keep-identity)
                KEEP_IDENTITY=true
                shift
                ;;
            --keep-config)
                KEEP_CONFIG=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                log_step "ARGUMENTS" "ERROR" "Unknown argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Check prerequisites
check_prerequisites() {
    log_step "PREREQUISITES" "START" "Checking required tools and services"
    
    local required_commands=("docker")
    validate_prerequisites "${required_commands[@]}"
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_step "PREREQUISITES" "ERROR" "Docker daemon is not running"
        exit 1
    fi
    
    log_step "PREREQUISITES" "SUCCESS" "All prerequisites met"
}

# Check container status
check_container_status() {
    log_step "CONTAINER_CHECK" "START" "Checking container status"
    
    local container_exists=false
    local container_running=false
    
    # Check if container exists
    if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        container_exists=true
        log_step "CONTAINER_CHECK" "INFO" "Container '$CONTAINER_NAME' exists"
        
        # Check if container is running
        if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            container_running=true
            log_step "CONTAINER_CHECK" "INFO" "Container '$CONTAINER_NAME' is running"
        else
            log_step "CONTAINER_CHECK" "INFO" "Container '$CONTAINER_NAME' is stopped"
        fi
    else
        log_step "CONTAINER_CHECK" "INFO" "Container '$CONTAINER_NAME' does not exist"
    fi
    
    echo "$container_exists $container_running"
}

# Stop container and processes
stop_container() {
    log_step "CONTAINER_STOP" "START" "Stopping container and Tezos processes"
    
    # Stop Tezos processes first
    if docker exec "$CONTAINER_NAME" pgrep -f tezos >/dev/null 2>&1; then
        log_step "CONTAINER_STOP" "INFO" "Stopping Tezos processes gracefully"
        docker exec "$CONTAINER_NAME" pkill -TERM -f tezos || true
        sleep 5
        
        # Force kill if still running
        if docker exec "$CONTAINER_NAME" pgrep -f tezos >/dev/null 2>&1; then
            log_step "CONTAINER_STOP" "INFO" "Force stopping remaining processes"
            docker exec "$CONTAINER_NAME" pkill -KILL -f tezos || true
        fi
    fi
    
    # Stop container
    log_step "CONTAINER_STOP" "INFO" "Stopping container '$CONTAINER_NAME'"
    if docker stop "$CONTAINER_NAME" >/dev/null 2>&1; then
        log_step "CONTAINER_STOP" "SUCCESS" "Container stopped successfully"
    else
        log_step "CONTAINER_STOP" "WARNING" "Container was already stopped or failed to stop"
    fi
}

# Analyze current data size
analyze_data_size() {
    log_step "DATA_ANALYSIS" "START" "Analyzing current data size"
    
    local status
    status=$(check_container_status)
    local container_exists container_running
    read -r container_exists container_running <<< "$status"
    
    if [ "$container_exists" = true ]; then
        # Get data directory size
        local data_size
        if data_size=$(docker exec "$CONTAINER_NAME" du -sh /.tezos-node 2>/dev/null | cut -f1); then
            log_step "DATA_ANALYSIS" "INFO" "Node data size: $data_size"
        else
            log_step "DATA_ANALYSIS" "WARNING" "Could not determine data size"
        fi
        
        # Show data structure
        log_step "DATA_ANALYSIS" "INFO" "Data directory structure:"
        docker exec "$CONTAINER_NAME" find /.tezos-node -maxdepth 2 -type d 2>/dev/null | sort | while read -r dir; do
            local dir_size
            dir_size=$(docker exec "$CONTAINER_NAME" du -sh "$dir" 2>/dev/null | cut -f1 || echo "unknown")
            log_step "DATA_ANALYSIS" "INFO" "  $dir ($dir_size)"
        done 2>/dev/null || true
        
        # Check for important files
        local important_files=("/.tezos-node/identity.json" "/.tezos-node/config.json" "/.tezos-client/secret_keys")
        for file in "${important_files[@]}"; do
            if docker exec "$CONTAINER_NAME" test -f "$file" 2>/dev/null; then
                log_step "DATA_ANALYSIS" "INFO" "Found: $file"
            fi
        done
    else
        log_step "DATA_ANALYSIS" "INFO" "Container does not exist, no data to analyze"
    fi
}

# Backup important files
backup_important_files() {
    log_step "BACKUP" "START" "Creating backup of important files"
    
    local backup_dir="./backups/pre_cleanup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Files to backup
    local backup_files=()
    
    if [ "$KEEP_IDENTITY" = false ]; then
        backup_files+=("/.tezos-node/identity.json")
    fi
    
    if [ "$KEEP_CONFIG" = false ]; then
        backup_files+=("/.tezos-node/config.json")
    fi
    
    # Always backup client keys
    backup_files+=("/.tezos-client/secret_keys")
    backup_files+=("/.tezos-client/public_keys")
    
    local backed_up_count=0
    for file in "${backup_files[@]}"; do
        if docker exec "$CONTAINER_NAME" test -f "$file" 2>/dev/null; then
            local filename
            filename=$(basename "$file")
            if docker cp "$CONTAINER_NAME:$file" "$backup_dir/$filename" 2>/dev/null; then
                log_step "BACKUP" "SUCCESS" "Backed up: $filename"
                backed_up_count=$((backed_up_count + 1))
            else
                log_step "BACKUP" "WARNING" "Failed to backup: $filename"
            fi
        fi
    done
    
    if [ $backed_up_count -gt 0 ]; then
        log_step "BACKUP" "SUCCESS" "Backup created: $backup_dir ($backed_up_count files)"
        echo "$backup_dir"
    else
        log_step "BACKUP" "INFO" "No files needed backup"
        rm -rf "$backup_dir"
        echo ""
    fi
}

# Get user confirmation
get_confirmation() {
    if [ "$FORCE_CLEANUP" = true ]; then
        log_step "CONFIRMATION" "INFO" "Force mode enabled, skipping confirmation"
        return 0
    fi
    
    log_step "CONFIRMATION" "WARNING" "This will delete ALL Tezos node data!"
    log_step "CONFIRMATION" "INFO" "Data that will be removed:"
    log_step "CONFIRMATION" "INFO" "- Blockchain data (blocks, operations, etc.)"
    log_step "CONFIRMATION" "INFO" "- Network state and peer information"
    log_step "CONFIRMATION" "INFO" "- Temporary and cache files"
    
    if [ "$KEEP_IDENTITY" = false ]; then
        log_step "CONFIRMATION" "WARNING" "- Node identity (will need to be regenerated)"
    else
        log_step "CONFIRMATION" "INFO" "- Node identity will be PRESERVED"
    fi
    
    if [ "$KEEP_CONFIG" = false ]; then
        log_step "CONFIRMATION" "WARNING" "- Node configuration (will need to be reconfigured)"
    else
        log_step "CONFIRMATION" "INFO" "- Node configuration will be PRESERVED"
    fi
    
    log_step "CONFIRMATION" "INFO" "Keys and wallet data will be backed up first"
    
    echo ""
    read -p "Are you sure you want to proceed? Type 'DELETE' to confirm: " confirmation
    
    if [ "$confirmation" = "DELETE" ]; then
        log_step "CONFIRMATION" "SUCCESS" "User confirmed data deletion"
        return 0
    else
        log_step "CONFIRMATION" "INFO" "Operation cancelled by user"
        return 1
    fi
}

# Clean blockchain data
clean_blockchain_data() {
    log_step "CLEAN_BLOCKCHAIN" "START" "Removing blockchain data"
    
    # Directories to clean (preserve identity and config based on options)
    local dirs_to_clean=(
        "/.tezos-node/store"
        "/.tezos-node/context"
        "/.tezos-node/protocol_runner"
        "/.tezos-node/locking"
        "/.tezos-node/logs"
        "/.tezos-node/tmp"
    )
    
    local files_to_clean=(
        "/.tezos-node/peers.json"
        "/.tezos-node/version.json"
    )
    
    # Add identity and config to cleanup if not preserving
    if [ "$KEEP_IDENTITY" = false ]; then
        files_to_clean+=("/.tezos-node/identity.json")
    fi
    
    if [ "$KEEP_CONFIG" = false ]; then
        files_to_clean+=("/.tezos-node/config.json")
    fi
    
    # Remove directories
    for dir in "${dirs_to_clean[@]}"; do
        if docker exec "$CONTAINER_NAME" test -d "$dir" 2>/dev/null; then
            if docker exec "$CONTAINER_NAME" rm -rf "$dir" 2>/dev/null; then
                log_step "CLEAN_BLOCKCHAIN" "SUCCESS" "Removed directory: $dir"
            else
                log_step "CLEAN_BLOCKCHAIN" "ERROR" "Failed to remove: $dir"
            fi
        else
            log_step "CLEAN_BLOCKCHAIN" "INFO" "Directory not found: $dir"
        fi
    done
    
    # Remove files
    for file in "${files_to_clean[@]}"; do
        if docker exec "$CONTAINER_NAME" test -f "$file" 2>/dev/null; then
            if docker exec "$CONTAINER_NAME" rm -f "$file" 2>/dev/null; then
                log_step "CLEAN_BLOCKCHAIN" "SUCCESS" "Removed file: $file"
            else
                log_step "CLEAN_BLOCKCHAIN" "ERROR" "Failed to remove: $file"
            fi
        else
            log_step "CLEAN_BLOCKCHAIN" "INFO" "File not found: $file"
        fi
    done
}

# Verify cleanup
verify_cleanup() {
    log_step "VERIFICATION" "START" "Verifying cleanup completion"
    
    # Check remaining data size
    local remaining_size
    if remaining_size=$(docker exec "$CONTAINER_NAME" du -sh /.tezos-node 2>/dev/null | cut -f1); then
        log_step "VERIFICATION" "INFO" "Remaining data size: $remaining_size"
    fi
    
    # Check what files remain
    log_step "VERIFICATION" "INFO" "Remaining files in /.tezos-node:"
    docker exec "$CONTAINER_NAME" find /.tezos-node -type f 2>/dev/null | while read -r file; do
        log_step "VERIFICATION" "INFO" "  $(basename "$file")"
    done || true
    
    # Verify preserved files if applicable
    if [ "$KEEP_IDENTITY" = true ]; then
        if docker exec "$CONTAINER_NAME" test -f "/.tezos-node/identity.json" 2>/dev/null; then
            log_step "VERIFICATION" "SUCCESS" "Identity file preserved"
        else
            log_step "VERIFICATION" "WARNING" "Identity file was not preserved (may not have existed)"
        fi
    fi
    
    if [ "$KEEP_CONFIG" = true ]; then
        if docker exec "$CONTAINER_NAME" test -f "/.tezos-node/config.json" 2>/dev/null; then
            log_step "VERIFICATION" "SUCCESS" "Config file preserved"
        else
            log_step "VERIFICATION" "WARNING" "Config file was not preserved (may not have existed)"
        fi
    fi
}

# Provide next steps guidance
provide_next_steps() {
    log_step "NEXT_STEPS" "INFO" "Node data cleanup completed successfully!"
    log_step "NEXT_STEPS" "INFO" "Next steps to restore operations:"
    
    if [ "$KEEP_IDENTITY" = false ]; then
        log_step "NEXT_STEPS" "INFO" "1. Node identity will be regenerated on first start"
    else
        log_step "NEXT_STEPS" "INFO" "1. Node identity preserved, no regeneration needed"
    fi
    
    log_step "NEXT_STEPS" "INFO" "2. Import fresh snapshot for faster sync:"
    log_step "NEXT_STEPS" "INFO" "   ./scripts/import_snapshot.sh [network]"
    log_step "NEXT_STEPS" "INFO" "3. Start node with docker compose:"
    log_step "NEXT_STEPS" "INFO" "   docker compose -f docker/compose.ghostnet.yml up -d"
    log_step "NEXT_STEPS" "INFO" "4. Monitor synchronization:"
    log_step "NEXT_STEPS" "INFO" "   ./scripts/check_sync.sh --monitor"
    
    if [ "$KEEP_CONFIG" = false ]; then
        log_step "NEXT_STEPS" "WARNING" "Configuration was removed - you may need to reconfigure network settings"
    fi
    
    log_step "NEXT_STEPS" "INFO" "Backup location (if created): ./backups/pre_cleanup_*"
}

# Show usage information
show_usage() {
    cat << EOF
Tezos Node Data Cleanup Tool

Usage: $0 [options]

Options:
  --force          Skip confirmation prompts
  --keep-identity  Preserve node identity files
  --keep-config    Preserve configuration files  
  --help, -h       Show this help message

Description:
  This script safely removes Tezos node data for fresh synchronization
  or troubleshooting. It creates backups of important files before cleanup.

What gets removed:
  - Blockchain data (blocks, operations, state)
  - Network and peer information
  - Logs and temporary files
  - Node identity (unless --keep-identity)
  - Configuration (unless --keep-config)

What gets preserved:
  - Client keys and wallet data (always backed up)
  - Files specified by keep options

Examples:
  $0                    # Interactive cleanup with confirmations
  $0 --force            # Clean all data without prompts
  $0 --keep-identity    # Preserve node identity
  $0 --keep-config --keep-identity  # Preserve config and identity

Safety Features:
  - Automatic backup of important files
  - Confirmation prompts (unless --force)
  - Container stop before cleanup
  - Verification after cleanup

Exit codes:
  0  Cleanup completed successfully
  1  Cleanup failed or was cancelled
  2  Configuration or prerequisite error
EOF
}

# Main execution
main() {
    # Parse arguments
    parse_arguments "$@"
    
    log_system_info
    
    check_prerequisites
    
    # Show cleanup configuration
    log_step "CONFIG" "INFO" "Cleanup configuration:"
    log_step "CONFIG" "INFO" "- Force mode: $([ "$FORCE_CLEANUP" = true ] && echo "enabled" || echo "disabled")"
    log_step "CONFIG" "INFO" "- Keep identity: $([ "$KEEP_IDENTITY" = true ] && echo "yes" || echo "no")"
    log_step "CONFIG" "INFO" "- Keep config: $([ "$KEEP_CONFIG" = true ] && echo "yes" || echo "no")"
    
    # Check current state
    local status
    status=$(check_container_status)
    local container_exists container_running
    read -r container_exists container_running <<< "$status"
    
    if [ "$container_exists" = false ]; then
        log_step "MAIN" "ERROR" "Container '$CONTAINER_NAME' does not exist - nothing to clean"
        exit 1
    fi
    
    # Analyze current data
    analyze_data_size
    
    # Get user confirmation
    if ! get_confirmation; then
        exit 0
    fi
    
    # Stop container if running
    if [ "$container_running" = true ]; then
        stop_container
    fi
    
    # Backup important files
    local backup_dir
    backup_dir=$(backup_important_files)
    
    # Perform cleanup
    clean_blockchain_data
    
    # Verify cleanup
    verify_cleanup
    
    # Provide guidance
    provide_next_steps
    
    log_step "CLEANUP_COMPLETE" "SUCCESS" "Node data cleanup completed successfully"
    if [ -n "$backup_dir" ]; then
        log_step "CLEANUP_COMPLETE" "INFO" "Backup available at: $backup_dir"
    fi
}

# Execute main function
main "$@"