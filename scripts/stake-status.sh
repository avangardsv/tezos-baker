#!/usr/bin/env bash
# Staking Status Check

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/health.sh"

# =============================================================================
# MAIN
# =============================================================================

main() {
    # Check node container
    if ! check_node_container; then
        exit 1
    fi
    
    echo ""
    log_info "=== STAKING STATUS ==="
    echo ""
    
    # Get baker address
    local baker_address
    baker_address=$(docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        show address "${BAKER_ALIAS}" 2>/dev/null | grep Hash: | awk '{print $2}')
    
    echo "Baker: ${BAKER_ALIAS} (${baker_address})"
    echo ""
    
    # Get balances
    echo "Balances:"
    local liquid
    liquid=$(docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        get balance for "${BAKER_ALIAS}" 2>/dev/null | grep -v Warning | awk '{print $1}')
    
    local full
    full=$(docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        get full balance for "${BAKER_ALIAS}" 2>/dev/null | grep -v Warning | awk '{print $1}')
    
    local staked
    staked=$(docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        get staked balance for "${BAKER_ALIAS}" 2>/dev/null | grep -v Warning | awk '{print $1}')
    
    echo "  Liquid:  ${liquid} ꜩ (available to spend/stake)"
    echo "  Staked:  ${staked} ꜩ (frozen for baking)"
    echo "  Total:   ${full} ꜩ"
    echo ""
    
    # Check delegate status
    echo "Delegation:"
    local delegate
    delegate=$(docker exec "${CONTAINER_PREFIX}-node" \
        octez-client -d /var/run/tezos/node/.tezos-client \
        --endpoint "http://${RPC_ADDR}:${RPC_PORT}" \
        get delegate for "${BAKER_ALIAS}" 2>/dev/null | grep -v Warning | head -1)
    echo "  ${delegate}"
    echo ""
    
    # RPC delegate info
    echo "Network Status:"
    local delegate_info
    if delegate_info=$(curl -s --max-time 5 "http://${RPC_ADDR}:${RPC_PORT}/chains/main/blocks/head/context/delegates/${baker_address}" 2>/dev/null); then
        echo "$delegate_info" | jq -r '
          "  Deactivated: \(.deactivated // "null")",
          "  Grace period: \(.grace_period // "N/A")",
          "  Staking balance: \(.staking_balance // "0")",
          "  Frozen deposits: \(.frozen_deposits // "0")"
        ' 2>/dev/null || log_warn "Unable to parse delegate info"
    else
        log_warn "Unable to fetch delegate info (may not be registered)"
    fi
    
    echo ""
    
    # Status check
    if [ "$staked" = "0" ]; then
        log_warn "WARNING: Zero staked balance!"
        echo ""
        echo "You will NOT receive baking/attesting rights without staking."
        echo ""
        echo "Quick fix:"
        echo "  npm run stake:all        # Stake all funds"
        echo ""
    else
        log_success "Staked: ${staked} ꜩ"
        echo ""
        echo "Rights will be assigned in ~14-21 days after first stake."
        echo ""
    fi
    
    echo "Other commands:"
    echo "  npm run stake:all         # Stake all available funds"
    echo ""
}

main "$@"
