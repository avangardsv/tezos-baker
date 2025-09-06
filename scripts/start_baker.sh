#!/usr/bin/env bash

# Tezos Baker - Baker and Endorser Start Script
# Starts the Tezos baker and endorser processes for a registered delegate
#
# Usage: ./start_baker.sh <account_alias> [network] [--baker-only|--endorser-only]
#   account_alias: Name of the delegate account (required)
#   network: ghostnet (default) or mainnet
#   --baker-only: Start only the baker process
#   --endorser-only: Start only the endorser process

set -euo pipefail

# Source logging library
source "$(dirname "$0")/lib/log.sh"

# Configuration
ACCOUNT_ALIAS="${1:-}"
NETWORK="${2:-ghostnet}"
CONTAINER_NAME="tezos-node"
START_MODE="both"

# Initialize script logging
log_script_start "Start baker/endorser for '$ACCOUNT_ALIAS' on $NETWORK"

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --baker-only)
                START_MODE="baker"
                shift
                ;;
            --endorser-only)
                START_MODE="endorser"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
}

# Validate parameters
validate_parameters() {
    log_step "VALIDATION" "START" "Validating input parameters"
    
    if [ -z "$ACCOUNT_ALIAS" ]; then
        log_step "VALIDATION" "ERROR" "Account alias is required"
        echo "Usage: $0 <account_alias> [network] [options]"
        exit 1
    fi
    
    case "$NETWORK" in
        "ghostnet"|"mainnet")
            log_step "VALIDATION" "SUCCESS" "Network '$NETWORK' is valid"
            ;;
        *)
            log_step "VALIDATION" "ERROR" "Invalid network '$NETWORK'. Use 'ghostnet' or 'mainnet'"
            exit 1
            ;;
    esac
    
    log_step "VALIDATION" "SUCCESS" "Account alias: '$ACCOUNT_ALIAS', Mode: $START_MODE"
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
    
    # Check if container exists and is running
    if ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_step "PREREQUISITES" "ERROR" "Container '$CONTAINER_NAME' is not running"
        log_step "PREREQUISITES" "INFO" "Start the node with: docker compose -f docker/compose.${NETWORK}.yml up -d"
        exit 1
    fi
    
    log_step "PREREQUISITES" "SUCCESS" "Container '$CONTAINER_NAME' is running"
}

# Check if account is registered as delegate
check_delegate_registration() {
    log_step "DELEGATE_CHECK" "START" "Verifying delegate registration for '$ACCOUNT_ALIAS'"
    
    local address
    if address=$(docker exec "$CONTAINER_NAME" tezos-client show address "$ACCOUNT_ALIAS" --show-secret 2>/dev/null | grep "Hash:" | awk '{print $2}'); then
        log_step "DELEGATE_CHECK" "INFO" "Account address: $address"
        
        # Check if registered as delegate
        if docker exec "$CONTAINER_NAME" tezos-client rpc get "/chains/main/blocks/head/context/delegates/$address" >/dev/null 2>&1; then
            log_step "DELEGATE_CHECK" "SUCCESS" "Account is registered as a delegate"
            
            # Get delegate information
            local delegate_info staking_balance
            if delegate_info=$(docker exec "$CONTAINER_NAME" tezos-client rpc get "/chains/main/blocks/head/context/delegates/$address" 2>/dev/null); then
                staking_balance=$(echo "$delegate_info" | jq -r '.staking_balance // "0"' 2>/dev/null || echo "unknown")
                log_step "DELEGATE_CHECK" "INFO" "Staking balance: $staking_balance"
            fi
        else
            log_step "DELEGATE_CHECK" "ERROR" "Account '$ACCOUNT_ALIAS' is not registered as a delegate"
            log_step "DELEGATE_CHECK" "INFO" "Register first with: ./scripts/register_delegate.sh $ACCOUNT_ALIAS $NETWORK"
            exit 1
        fi
    else
        log_step "DELEGATE_CHECK" "ERROR" "Account '$ACCOUNT_ALIAS' does not exist"
        exit 1
    fi
}

# Check node synchronization
check_node_sync() {
    log_step "SYNC_CHECK" "START" "Checking node synchronization status"
    
    if docker exec "$CONTAINER_NAME" tezos-client bootstrapped >/dev/null 2>&1; then
        log_step "SYNC_CHECK" "SUCCESS" "Node is bootstrapped and synchronized"
    else
        log_step "SYNC_CHECK" "ERROR" "Node is not synchronized"
        log_step "SYNC_CHECK" "INFO" "Wait for sync or check with: ./scripts/check_sync.sh"
        exit 1
    fi
}

# Check if baker/endorser processes are already running
check_existing_processes() {
    log_step "PROCESS_CHECK" "START" "Checking for existing baker/endorser processes"
    
    local baker_running=false
    local endorser_running=false
    
    # Check for baker process
    if docker exec "$CONTAINER_NAME" pgrep -f "tezos-baker.*$ACCOUNT_ALIAS" >/dev/null 2>&1; then
        baker_running=true
        local baker_pid
        baker_pid=$(docker exec "$CONTAINER_NAME" pgrep -f "tezos-baker.*$ACCOUNT_ALIAS" 2>/dev/null | head -1)
        log_step "PROCESS_CHECK" "WARNING" "Baker is already running (PID: $baker_pid)"
    fi
    
    # Check for endorser process
    if docker exec "$CONTAINER_NAME" pgrep -f "tezos-endorser.*$ACCOUNT_ALIAS" >/dev/null 2>&1; then
        endorser_running=true
        local endorser_pid
        endorser_pid=$(docker exec "$CONTAINER_NAME" pgrep -f "tezos-endorser.*$ACCOUNT_ALIAS" 2>/dev/null | head -1)
        log_step "PROCESS_CHECK" "WARNING" "Endorser is already running (PID: $endorser_pid)"
    fi
    
    # Stop existing processes if requested
    if [ "$baker_running" = true ] && [ "$START_MODE" != "endorser" ]; then
        log_step "PROCESS_CHECK" "INFO" "Stopping existing baker process"
        docker exec "$CONTAINER_NAME" pkill -f "tezos-baker.*$ACCOUNT_ALIAS" || true
        sleep 3
    fi
    
    if [ "$endorser_running" = true ] && [ "$START_MODE" != "baker" ]; then
        log_step "PROCESS_CHECK" "INFO" "Stopping existing endorser process"  
        docker exec "$CONTAINER_NAME" pkill -f "tezos-endorser.*$ACCOUNT_ALIAS" || true
        sleep 3
    fi
}

# Start baker process
start_baker() {
    log_step "BAKER_START" "START" "Starting Tezos baker for '$ACCOUNT_ALIAS'"
    
    # Determine protocol version
    local protocol
    if protocol=$(docker exec "$CONTAINER_NAME" tezos-client rpc get /chains/main/blocks/head/protocol 2>/dev/null); then
        log_step "BAKER_START" "INFO" "Current protocol: $protocol"
    fi
    
    # Start baker (using alpha version as default)
    local baker_cmd="tezos-baker-alpha run with local node ~/.tezos-node $ACCOUNT_ALIAS"
    
    if docker exec -d "$CONTAINER_NAME" bash -c "$baker_cmd" >/dev/null 2>&1; then
        sleep 3
        
        # Verify baker started
        if docker exec "$CONTAINER_NAME" pgrep -f "tezos-baker.*$ACCOUNT_ALIAS" >/dev/null 2>&1; then
            local baker_pid
            baker_pid=$(docker exec "$CONTAINER_NAME" pgrep -f "tezos-baker.*$ACCOUNT_ALIAS" | head -1)
            log_step "BAKER_START" "SUCCESS" "Baker started successfully (PID: $baker_pid)"
        else
            log_step "BAKER_START" "ERROR" "Baker failed to start"
            return 1
        fi
    else
        log_step "BAKER_START" "ERROR" "Failed to execute baker command"
        return 1
    fi
}

# Start endorser process
start_endorser() {
    log_step "ENDORSER_START" "START" "Starting Tezos endorser for '$ACCOUNT_ALIAS'"
    
    # Start endorser (using alpha version as default)
    local endorser_cmd="tezos-endorser-alpha run $ACCOUNT_ALIAS"
    
    if docker exec -d "$CONTAINER_NAME" bash -c "$endorser_cmd" >/dev/null 2>&1; then
        sleep 3
        
        # Verify endorser started
        if docker exec "$CONTAINER_NAME" pgrep -f "tezos-endorser.*$ACCOUNT_ALIAS" >/dev/null 2>&1; then
            local endorser_pid
            endorser_pid=$(docker exec "$CONTAINER_NAME" pgrep -f "tezos-endorser.*$ACCOUNT_ALIAS" | head -1)
            log_step "ENDORSER_START" "SUCCESS" "Endorser started successfully (PID: $endorser_pid)"
        else
            log_step "ENDORSER_START" "ERROR" "Endorser failed to start"
            return 1
        fi
    else
        log_step "ENDORSER_START" "ERROR" "Failed to execute endorser command"
        return 1
    fi
}

# Monitor initial process health
monitor_processes() {
    log_step "PROCESS_MONITOR" "START" "Monitoring process health for 30 seconds"
    
    local monitor_duration=30
    local check_interval=5
    local checks=$((monitor_duration / check_interval))
    
    for i in $(seq 1 $checks); do
        local baker_ok=true
        local endorser_ok=true
        
        # Check baker if it should be running
        if [ "$START_MODE" != "endorser" ]; then
            if ! docker exec "$CONTAINER_NAME" pgrep -f "tezos-baker.*$ACCOUNT_ALIAS" >/dev/null 2>&1; then
                baker_ok=false
            fi
        fi
        
        # Check endorser if it should be running
        if [ "$START_MODE" != "baker" ]; then
            if ! docker exec "$CONTAINER_NAME" pgrep -f "tezos-endorser.*$ACCOUNT_ALIAS" >/dev/null 2>&1; then
                endorser_ok=false
            fi
        fi
        
        if [ "$baker_ok" = true ] && [ "$endorser_ok" = true ]; then
            log_step "PROCESS_MONITOR" "SUCCESS" "Check $i/$checks: All processes healthy"
        else
            log_step "PROCESS_MONITOR" "ERROR" "Check $i/$checks: Process health check failed"
            return 1
        fi
        
        if [ $i -lt $checks ]; then
            sleep $check_interval
        fi
    done
    
    log_step "PROCESS_MONITOR" "SUCCESS" "Process monitoring completed successfully"
}

# Provide operational guidance
provide_guidance() {
    log_step "GUIDANCE" "INFO" "Baker/endorser startup completed successfully!"
    log_step "GUIDANCE" "INFO" "Operational commands:"
    log_step "GUIDANCE" "INFO" "- Check process status: docker exec $CONTAINER_NAME ps aux | grep tezos"
    log_step "GUIDANCE" "INFO" "- View baker logs: docker exec $CONTAINER_NAME tail -f ~/.tezos-node/logs/baker.log"
    log_step "GUIDANCE" "INFO" "- View endorser logs: docker exec $CONTAINER_NAME tail -f ~/.tezos-node/logs/endorser.log"
    log_step "GUIDANCE" "INFO" "- Monitor sync: ./scripts/check_sync.sh --monitor"
    log_step "GUIDANCE" "INFO" "- Stop processes: docker exec $CONTAINER_NAME pkill -f 'tezos-(baker|endorser)'"
    
    if [ "$NETWORK" = "mainnet" ]; then
        log_step "GUIDANCE" "WARNING" "MAINNET: Monitor closely for missed baking/endorsing opportunities"
        log_step "GUIDANCE" "INFO" "Set up proper monitoring and alerting before leaving unattended"
    fi
}

# Show usage information
show_usage() {
    cat << EOF
Tezos Baker/Endorser Startup

Usage: $0 <account_alias> [network] [options]

Parameters:
  account_alias  Name of the registered delegate account (required)
  network        Network to operate on (ghostnet|mainnet) [default: ghostnet]

Options:
  --baker-only     Start only the baker process
  --endorser-only  Start only the endorser process
  --help, -h       Show this help message

Prerequisites:
  - Tezos node running and synchronized
  - Account registered as delegate
  - Sufficient balance for baking operations

Examples:
  $0 alice                    # Start both baker and endorser for 'alice' on ghostnet
  $0 baker mainnet            # Start both processes for 'baker' on mainnet
  $0 alice ghostnet --baker-only    # Start only baker for 'alice' on ghostnet

Process Management:
  - Processes run in the background within the Tezos container
  - Use 'docker logs' or process monitoring to track activity
  - Stop with: docker exec $CONTAINER_NAME pkill -f "tezos-(baker|endorser)"

Exit codes:
  0  Processes started successfully
  1  Failed to start processes
  2  Configuration or prerequisite error
EOF
}

# Main execution
main() {
    # Parse arguments first
    parse_arguments "$@"
    
    # Shift processed arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --baker-only|--endorser-only|--help|-h)
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    log_system_info
    
    validate_parameters
    check_prerequisites
    check_delegate_registration
    check_node_sync
    check_existing_processes
    
    # Start processes based on mode
    case "$START_MODE" in
        "baker")
            start_baker
            ;;
        "endorser")
            start_endorser
            ;;
        "both")
            start_baker
            start_endorser
            ;;
    esac
    
    monitor_processes
    provide_guidance
}

# Execute main function
main "$@"