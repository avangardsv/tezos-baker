#!/usr/bin/env bash

# Tezos Baker - Delegate Registration Script
# Registers a Tezos account as a delegate to enable baking and endorsing
#
# Usage: ./register_delegate.sh <account_alias> [network]
#   account_alias: Name of the account to register (required)
#   network: ghostnet (default) or mainnet

set -euo pipefail

# Source logging library
source "$(dirname "$0")/lib/log.sh"

# Configuration
ACCOUNT_ALIAS="${1:-}"
NETWORK="${2:-ghostnet}"
CONTAINER_NAME="tezos-node"
MIN_BALANCE_MAINNET=6000
MIN_BALANCE_GHOSTNET=1000

# Initialize script logging
log_script_start "Register '$ACCOUNT_ALIAS' as delegate on $NETWORK"

# Validate parameters
validate_parameters() {
    log_step "VALIDATION" "START" "Validating input parameters"
    
    if [ -z "$ACCOUNT_ALIAS" ]; then
        log_step "VALIDATION" "ERROR" "Account alias is required"
        echo "Usage: $0 <account_alias> [network]"
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
    
    log_step "VALIDATION" "SUCCESS" "Account alias: '$ACCOUNT_ALIAS'"
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

# Check if account exists
check_account_exists() {
    log_step "ACCOUNT_CHECK" "START" "Checking if account '$ACCOUNT_ALIAS' exists"
    
    if docker exec "$CONTAINER_NAME" tezos-client show address "$ACCOUNT_ALIAS" >/dev/null 2>&1; then
        local address
        address=$(docker exec "$CONTAINER_NAME" tezos-client show address "$ACCOUNT_ALIAS" --show-secret | grep "Hash:" | awk '{print $2}')
        log_step "ACCOUNT_CHECK" "SUCCESS" "Account exists with address: $address"
        echo "$address"
    else
        log_step "ACCOUNT_CHECK" "ERROR" "Account '$ACCOUNT_ALIAS' does not exist"
        log_step "ACCOUNT_CHECK" "INFO" "Create account with: docker exec $CONTAINER_NAME tezos-client gen keys $ACCOUNT_ALIAS"
        exit 1
    fi
}

# Check account balance
check_account_balance() {
    local address="$1"
    
    log_step "BALANCE_CHECK" "START" "Checking balance for account '$ACCOUNT_ALIAS'"
    
    local balance_tz balance_mutez min_balance
    
    case "$NETWORK" in
        "mainnet")
            min_balance=$MIN_BALANCE_MAINNET
            ;;
        "ghostnet") 
            min_balance=$MIN_BALANCE_GHOSTNET
            ;;
    esac
    
    if balance_tz=$(docker exec "$CONTAINER_NAME" tezos-client get balance for "$ACCOUNT_ALIAS" 2>/dev/null | grep -oE '[0-9]+\.?[0-9]*' | head -1); then
        # Convert to integer for comparison (remove decimal)
        balance_mutez=$(echo "$balance_tz" | awk '{printf "%.0f", $1 * 1000000}')
        local balance_int
        balance_int=$(echo "$balance_tz" | awk '{printf "%.0f", $1}')
        
        log_step "BALANCE_CHECK" "INFO" "Current balance: $balance_tz XTZ"
        
        if [ "$balance_int" -ge "$min_balance" ]; then
            log_step "BALANCE_CHECK" "SUCCESS" "Balance is sufficient for delegation ($balance_tz >= $min_balance XTZ)"
        else
            log_step "BALANCE_CHECK" "WARNING" "Balance is below recommended minimum ($balance_tz < $min_balance XTZ)"
            if [ "$NETWORK" = "mainnet" ]; then
                log_step "BALANCE_CHECK" "ERROR" "Insufficient balance for mainnet baking. Need at least $min_balance XTZ"
                exit 1
            else
                log_step "BALANCE_CHECK" "INFO" "Proceeding on testnet with current balance"
            fi
        fi
    else
        log_step "BALANCE_CHECK" "ERROR" "Failed to get balance for account '$ACCOUNT_ALIAS'"
        exit 1
    fi
}

# Check if already registered as delegate
check_existing_registration() {
    local address="$1"
    
    log_step "REGISTRATION_CHECK" "START" "Checking if account is already registered as delegate"
    
    # Check if account is in the delegates list
    if docker exec "$CONTAINER_NAME" tezos-client rpc get "/chains/main/blocks/head/context/delegates/$address" >/dev/null 2>&1; then
        log_step "REGISTRATION_CHECK" "INFO" "Account is already registered as a delegate"
        
        # Get delegate information
        local delegate_info
        if delegate_info=$(docker exec "$CONTAINER_NAME" tezos-client rpc get "/chains/main/blocks/head/context/delegates/$address" 2>/dev/null); then
            local staking_balance voting_power
            staking_balance=$(echo "$delegate_info" | jq -r '.staking_balance // "0"' 2>/dev/null || echo "unknown")
            voting_power=$(echo "$delegate_info" | jq -r '.voting_power // "0"' 2>/dev/null || echo "unknown")
            
            log_step "REGISTRATION_CHECK" "INFO" "Staking balance: $staking_balance"
            log_step "REGISTRATION_CHECK" "INFO" "Voting power: $voting_power"
        fi
        
        return 0
    else
        log_step "REGISTRATION_CHECK" "INFO" "Account is not yet registered as a delegate"
        return 1
    fi
}

# Register account as delegate
register_delegate() {
    local address="$1"
    
    log_step "DELEGATE_REGISTRATION" "START" "Registering '$ACCOUNT_ALIAS' as delegate"
    
    # Perform the registration
    if docker exec "$CONTAINER_NAME" tezos-client register key "$ACCOUNT_ALIAS" as delegate 2>&1 | tee -a "$LOG_FILE"; then
        log_step "DELEGATE_REGISTRATION" "SUCCESS" "Successfully submitted registration transaction"
        
        # Wait for operation to be included in a block
        log_step "DELEGATE_REGISTRATION" "INFO" "Waiting for registration to be confirmed..."
        sleep 60  # Wait for block confirmation
        
        # Verify registration
        if check_existing_registration "$address"; then
            log_step "DELEGATE_REGISTRATION" "SUCCESS" "Registration confirmed on blockchain"
        else
            log_step "DELEGATE_REGISTRATION" "WARNING" "Registration submitted but not yet confirmed"
            log_step "DELEGATE_REGISTRATION" "INFO" "Check status later with: docker exec $CONTAINER_NAME tezos-client rpc get /chains/main/blocks/head/context/delegates/$address"
        fi
        
    else
        log_step "DELEGATE_REGISTRATION" "ERROR" "Failed to register delegate"
        exit 1
    fi
}

# Check baking and endorsing rights
check_rights() {
    local address="$1"
    
    log_step "RIGHTS_CHECK" "START" "Checking baking and endorsing rights"
    
    # Get current cycle
    local current_level cycle
    if current_level=$(docker exec "$CONTAINER_NAME" tezos-client rpc get /chains/main/blocks/head/header | jq -r '.level' 2>/dev/null); then
        cycle=$((current_level / 8192))  # Approximate cycle calculation
        log_step "RIGHTS_CHECK" "INFO" "Current level: $current_level, cycle: ~$cycle"
    fi
    
    # Check baking rights for next few levels
    local baking_rights
    if baking_rights=$(docker exec "$CONTAINER_NAME" tezos-client rpc get "/chains/main/blocks/head/helpers/baking_rights?delegate=$address&max_priority=5&cycle=$((cycle+1))" 2>/dev/null | jq '. | length' 2>/dev/null); then
        if [ "$baking_rights" -gt 0 ]; then
            log_step "RIGHTS_CHECK" "SUCCESS" "Found $baking_rights baking rights in upcoming cycle"
        else
            log_step "RIGHTS_CHECK" "INFO" "No baking rights found in next cycle (normal for new delegates)"
        fi
    fi
    
    # Check endorsing rights
    local endorsing_rights
    if endorsing_rights=$(docker exec "$CONTAINER_NAME" tezos-client rpc get "/chains/main/blocks/head/helpers/endorsing_rights?delegate=$address&cycle=$((cycle+1))" 2>/dev/null | jq '. | length' 2>/dev/null); then
        if [ "$endorsing_rights" -gt 0 ]; then
            log_step "RIGHTS_CHECK" "SUCCESS" "Found $endorsing_rights endorsing rights in upcoming cycle"
        else
            log_step "RIGHTS_CHECK" "INFO" "No endorsing rights found in next cycle (normal for new delegates)"
        fi
    fi
}

# Provide next steps guidance
provide_next_steps() {
    local address="$1"
    
    log_step "NEXT_STEPS" "INFO" "Delegate registration completed successfully!"
    log_step "NEXT_STEPS" "INFO" "Next steps to start baking:"
    log_step "NEXT_STEPS" "INFO" "1. Wait for rights allocation (may take 5+ cycles)"
    log_step "NEXT_STEPS" "INFO" "2. Start baker: docker exec -d $CONTAINER_NAME tezos-baker-alpha run with local node ~/.tezos-node $ACCOUNT_ALIAS"
    log_step "NEXT_STEPS" "INFO" "3. Start endorser: docker exec -d $CONTAINER_NAME tezos-endorser-alpha run $ACCOUNT_ALIAS"
    log_step "NEXT_STEPS" "INFO" "4. Monitor with: ./scripts/check_sync.sh --monitor"
    log_step "NEXT_STEPS" "INFO" "5. Check logs: docker logs tezos-baker && docker logs tezos-endorser"
    
    if [ "$NETWORK" = "ghostnet" ]; then
        log_step "NEXT_STEPS" "INFO" "Testnet tip: Request more funds at https://faucet.ghostnet.teztnets.xyz/"
    else
        log_step "NEXT_STEPS" "WARNING" "Mainnet: Ensure proper security measures and monitoring before starting"
    fi
}

# Show usage information
show_usage() {
    cat << EOF
Tezos Delegate Registration

Usage: $0 <account_alias> [network]

Parameters:
  account_alias  Name of the account to register as delegate (required)
  network        Network to register on (ghostnet|mainnet) [default: ghostnet]

Prerequisites:
  - Tezos node running and synchronized
  - Account created with sufficient balance
  - Network connectivity

Examples:
  $0 alice                    # Register 'alice' as delegate on ghostnet
  $0 baker mainnet            # Register 'baker' as delegate on mainnet

Minimum Balance Requirements:
  - Ghostnet: $MIN_BALANCE_GHOSTNET XTZ (for testing)
  - Mainnet: $MIN_BALANCE_MAINNET XTZ (for effective baking)

Exit codes:
  0  Registration successful
  1  Registration failed or insufficient balance
  2  Script execution error
EOF
}

# Main execution
main() {
    # Check for help flag
    case "${1:-}" in
        --help|-h)
            show_usage
            exit 0
            ;;
    esac
    
    log_system_info
    
    validate_parameters
    check_prerequisites
    
    local address
    address=$(check_account_exists)
    
    check_account_balance "$address"
    
    # Check if already registered
    if check_existing_registration "$address"; then
        log_step "REGISTRATION_COMPLETE" "SUCCESS" "Account '$ACCOUNT_ALIAS' is already a registered delegate"
        check_rights "$address"
        provide_next_steps "$address"
    else
        register_delegate "$address"
        check_rights "$address"
        provide_next_steps "$address"
    fi
}

# Execute main function
main "$@"