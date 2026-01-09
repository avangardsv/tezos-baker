#!/usr/bin/env bash
# Verify DAL is working correctly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/common.sh"

main() {
    local dal_container="${CONTAINER_PREFIX:-tezos}-dal-node"
    local baker_container="${CONTAINER_PREFIX:-tezos}-baker"
    local errors=0

    echo ""
    log_info "=== DAL Verification ==="
    echo ""

    # Check 1: DAL container running
    if docker ps --format '{{.Names}}' | grep -q "^${dal_container}$"; then
        log_success "DAL node container is running"
    else
        log_error "DAL node container is NOT running"
        ((errors++))
    fi

    # Check 2: Baker container running
    if docker ps --format '{{.Names}}' | grep -q "^${baker_container}$"; then
        log_success "Baker container is running"
    else
        log_error "Baker container is NOT running"
        ((errors++))
    fi

    # Check 3: DAL node health
    if docker logs --tail 20 "$dal_container" 2>/dev/null | grep -q "RPC server is listening"; then
        log_success "DAL RPC server is listening"
    else
        log_warn "DAL RPC server status unclear"
    fi

    # Check 4: DAL P2P connections
    if docker logs --tail 20 "$dal_container" 2>/dev/null | grep -q "New_connection"; then
        log_success "DAL has P2P connections"
    else
        log_warn "No DAL P2P connections seen in recent logs"
    fi

    # Check 5: Baker DAL attestations
    if docker logs --since 5m "$baker_container" 2>&1 | grep -q "with DAL"; then
        log_success "Baker is sending DAL attestations!"
        echo ""
        log_info "Recent DAL attestations:"
        docker logs --since 5m "$baker_container" 2>&1 | grep "with DAL" | tail -5
    else
        log_warn "No DAL attestations in last 5 minutes"
        log_info "This is normal if you don't have attesting rights yet"
    fi

    echo ""

    if [ $errors -eq 0 ]; then
        log_success "✅ DAL verification complete - all checks passed!"
    else
        log_error "❌ DAL verification found $errors error(s)"
        exit 1
    fi
}

main "$@"
