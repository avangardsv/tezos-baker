#!/usr/bin/env bash
# Stake Funds Script
# Usage: ./stake-funds.sh [all|half|minimum|<amount>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/health.sh"

# =============================================================================
# MAIN
# =============================================================================

main() {
    # Preflight checks
    if ! preflight_node_check; then
        log_error "Preflight checks failed. Cannot stake funds."
        exit 1
    fi
    
    echo ""
    log_info "=== STAKE FUNDS ==="
    echo ""
    
    # Get current balances
    local full_balance
    full_balance=$(docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        get full balance for "${BAKER_ALIAS}" 2>/dev/null | grep -v Warning | awk '{print $1}')
    
    local staked_balance
    staked_balance=$(docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        get staked balance for "${BAKER_ALIAS}" 2>/dev/null | grep -v Warning | awk '{print $1}')
    
    local liquid_balance
    liquid_balance=$(docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        get balance for "${BAKER_ALIAS}" 2>/dev/null | grep -v Warning | awk '{print $1}')

    echo "Current balances:"
    echo "  Liquid:  ${liquid_balance} ꜩ"
    echo "  Staked:  ${staked_balance} ꜩ"
    echo "  Total:   ${full_balance} ꜩ"
    echo ""
    
    # Check if has liquid balance
    local available
    if command -v bc >/dev/null 2>&1; then
        available=$(echo "$liquid_balance - 0.5" | bc)
        if (( $(echo "$available <= 0" | bc -l) )); then
            log_error "No liquid balance available to stake"
            exit 1
        fi
    else
        log_warn "bc not found, skipping balance check"
        available="$liquid_balance"
    fi
    
    # Determine stake amount
    local mode="${1:-interactive}"
    local stake_amount=""
    
    case $mode in
        all)
            if command -v bc >/dev/null 2>&1; then
                stake_amount=$(echo "$liquid_balance - 0.5" | bc)
            else
                log_error "bc required for 'all' mode"
                exit 1
            fi
            log_info "Mode: Stake ALL (${stake_amount} ꜩ, reserve 0.5 for fees)"
            ;;
        half)
            if command -v bc >/dev/null 2>&1; then
                stake_amount=$(echo "$liquid_balance / 2" | bc)
            else
                log_error "bc required for 'half' mode"
                exit 1
            fi
            log_info "Mode: Stake HALF (${stake_amount} ꜩ)"
            ;;
        minimum)
            stake_amount=6000
            log_info "Mode: Stake MINIMUM (${stake_amount} ꜩ)"
            if command -v bc >/dev/null 2>&1 && (( $(echo "$liquid_balance < 6000" | bc -l) )); then
                log_error "Need 6,000 ꜩ, have ${liquid_balance} ꜩ"
                exit 1
            fi
            ;;
        interactive)
            echo "Choose stake amount:"
            if command -v bc >/dev/null 2>&1; then
                echo "  1) All funds       ($(echo "$liquid_balance - 0.5" | bc) ꜩ)"
                echo "  2) Half funds      ($(echo "$liquid_balance / 2" | bc) ꜩ)"
            else
                echo "  1) All funds       (${liquid_balance} ꜩ)"
                echo "  2) Half funds      (N/A - bc not found)"
            fi
            echo "  3) Minimum         (6,000 ꜩ)"
            echo "  4) Custom amount"
            echo ""
            read -p "Choice (1-4): " choice
            
            case $choice in
                1)
                    if command -v bc >/dev/null 2>&1; then
                        stake_amount=$(echo "$liquid_balance - 0.5" | bc)
                    else
                        stake_amount="$liquid_balance"
                    fi
                    ;;
                2)
                    if command -v bc >/dev/null 2>&1; then
                        stake_amount=$(echo "$liquid_balance / 2" | bc)
                    else
                        log_error "bc required for 'half' mode"
                        exit 1
                    fi
                    ;;
                3)
                    stake_amount=6000
                    if command -v bc >/dev/null 2>&1 && (( $(echo "$liquid_balance < 6000" | bc -l) )); then
                        log_error "Insufficient balance"
                        exit 1
                    fi
                    ;;
                4)
                    read -p "Enter amount (ꜩ): " stake_amount
                    ;;
                *)
                    log_error "Invalid choice"
                    exit 1
                    ;;
            esac
            ;;
        *)
            stake_amount=$mode
            log_info "Mode: Custom (${stake_amount} ꜩ)"
            ;;
    esac
    
    # Validate
    if command -v bc >/dev/null 2>&1; then
        if (( $(echo "$stake_amount <= 0" | bc -l) )); then
            log_error "Invalid amount: ${stake_amount}"
            exit 1
        fi
        
        if (( $(echo "$stake_amount > $liquid_balance" | bc -l) )); then
            log_error "Insufficient balance (need ${stake_amount} ꜩ, have ${liquid_balance} ꜩ)"
            exit 1
        fi
    fi
    
    echo ""
    echo "Summary:"
    echo "  Amount to stake: ${stake_amount} ꜩ"
    if command -v bc >/dev/null 2>&1; then
        echo "  After staking:"
        echo "    Liquid: $(echo "$liquid_balance - $stake_amount" | bc) ꜩ"
        echo "    Staked: $(echo "$staked_balance + $stake_amount" | bc) ꜩ"
    fi
    echo ""
    echo "Note: Staked funds are frozen. Rights assigned in ~14-21 days."
    echo ""
    
    # Confirm
    if [ "$mode" != "interactive" ]; then
        read -p "Proceed? (yes/no): " confirm
        if [ "$confirm" != "yes" ] && [ "$confirm" != "y" ]; then
            log_info "Cancelled"
            exit 0
        fi
    fi
    
    echo ""
    log_info "Staking ${stake_amount} ꜩ..."
    echo ""
    
    # Execute
    docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        stake "${stake_amount}" for "${BAKER_ALIAS}"
    
    echo ""
    log_success "Stake operation submitted"
    echo ""
    log_info "Waiting 10 seconds for confirmation..."
    sleep 10
    
    # Show new balances
    local new_staked
    new_staked=$(docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        get staked balance for "${BAKER_ALIAS}" 2>/dev/null | grep -v Warning)
    
    local new_liquid
    new_liquid=$(docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        get balance for "${BAKER_ALIAS}" 2>/dev/null | grep -v Warning)
    
    echo ""
    echo "New balances:"
    echo "  Liquid:  ${new_liquid}"
    echo "  Staked:  ${new_staked}"
    echo ""
    echo "Next steps:"
    echo "  1. Check status: npm run stake:status"
    echo "  2. Wait 14-21 days for baking rights"
    
    local baker_addr
    baker_addr=$(docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        show address "${BAKER_ALIAS}" 2>/dev/null | grep Hash: | awk '{print $2}')
    echo "  3. View on explorer: https://ghostnet.tzkt.io/${baker_addr}"
    echo ""
}

main "$@"
