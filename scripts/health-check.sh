#!/usr/bin/env bash
# Node health check script - runs every hour via cron
# Collects metrics and pushes status to GitHub for Actions monitoring

set -e

# Load shared library
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/lib/common.sh"

# Configuration
STATUS_FILE="logs/node-status.json"
TEMP_LOG="/tmp/tezos-health-check.log"
CONTAINER=$(get_container_name)

# Create logs directory
mkdir -p logs

# Print header
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  TEZOS NODE HEALTH CHECK${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Collect last 10 minutes of logs for error analysis
log_info "Analyzing node logs (last 10 minutes)..."
docker logs --since 10m "$CONTAINER" 2>&1 > "$TEMP_LOG" 2>/dev/null || {
    log_error "Failed to get docker logs from container"
    exit 1
}

ERROR_COUNT=$(grep -ci "error" "$TEMP_LOG" 2>/dev/null | tail -1 || echo "0")
WARN_COUNT=$(grep -ci "warn" "$TEMP_LOG" 2>/dev/null | tail -1 || echo "0")

# Get metrics using shared RPC functions
log_info "Fetching network metrics..."
PEERS=$(rpc_get_peer_count)

log_info "Checking block sync status..."
NODE_LEVEL=$(rpc_get_block_level)
NODE_TIMESTAMP=$(rpc_get_block_timestamp)
SYNC_LAG=$(get_sync_lag "$NODE_TIMESTAMP")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Display metrics
echo ""
echo -e "${BOLD}METRICS SUMMARY${NC}"
echo -e "────────────────────────────────────────────────────────────"
printf "  %-25s %s\n" "Network Peers:" "${PEERS}/36"
printf "  %-25s %s\n" "Block Height:" "${NODE_LEVEL}"
printf "  %-25s %s\n" "Sync Lag:" "$(seconds_to_human $SYNC_LAG) behind"
printf "  %-25s %s\n" "Errors (10min):" "${ERROR_COUNT}"
printf "  %-25s %s\n" "Warnings (10min):" "${WARN_COUNT}"
echo ""

# Determine alert level based on actual node health
ALERT_LEVEL="healthy"
ALERT_MESSAGE="Node operating normally"
SEVERITY="OK"
COLOR="${GREEN}"

# Check for critical conditions (sync issues are highest priority)
if [ "$SYNC_LAG" -gt 3600 ]; then
    ALERT_LEVEL="critical"
    ALERT_MESSAGE="Node stuck $(seconds_to_human $SYNC_LAG) behind blockchain (not syncing)"
    SEVERITY="CRITICAL"
    COLOR="${RED}"
elif [ "$PEERS" -eq 0 ]; then
    ALERT_LEVEL="critical"
    ALERT_MESSAGE="No network peers connected"
    SEVERITY="CRITICAL"
    COLOR="${RED}"
elif [ "$ERROR_COUNT" -gt 50 ]; then
    ALERT_LEVEL="critical"
    ALERT_MESSAGE="High error rate detected ($ERROR_COUNT errors in 10min)"
    SEVERITY="CRITICAL"
    COLOR="${RED}"
elif [ "$PEERS" -lt 5 ]; then
    ALERT_LEVEL="critical"
    ALERT_MESSAGE="Very low peer count ($PEERS peers)"
    SEVERITY="CRITICAL"
    COLOR="${RED}"
# Check for warning conditions
elif [ "$SYNC_LAG" -gt 600 ]; then
    ALERT_LEVEL="warning"
    ALERT_MESSAGE="Node sync lagging $(seconds_to_human $SYNC_LAG) behind"
    SEVERITY="WARNING"
    COLOR="${YELLOW}"
elif [ "$ERROR_COUNT" -gt 20 ]; then
    ALERT_LEVEL="warning"
    ALERT_MESSAGE="Elevated error rate ($ERROR_COUNT errors in 10min)"
    SEVERITY="WARNING"
    COLOR="${YELLOW}"
elif [ "$PEERS" -lt 20 ]; then
    ALERT_LEVEL="warning"
    ALERT_MESSAGE="Low peer count ($PEERS peers, target 36)"
    SEVERITY="WARNING"
    COLOR="${YELLOW}"
fi

# Print status
echo -e "${BOLD}HEALTH STATUS${NC}"
echo -e "────────────────────────────────────────────────────────────"
echo -e "  Level:     ${COLOR}[${SEVERITY}]${NC}"
echo -e "  Message:   ${ALERT_MESSAGE}"
echo -e "  Timestamp: ${TIMESTAMP}"
echo ""

# Write status JSON
log_info "Writing status to ${BOLD}${STATUS_FILE}${NC}..."
cat > "$STATUS_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "alert_level": "$ALERT_LEVEL",
  "alert_message": "$ALERT_MESSAGE",
  "peers": "$PEERS",
  "block_level": "$NODE_LEVEL",
  "sync_lag_seconds": "$SYNC_LAG",
  "errors_last_10min": "$ERROR_COUNT",
  "warnings_last_10min": "$WARN_COUNT"
}
EOF

# Commit and push to trigger GitHub Actions
if [ -n "$(git status --porcelain "$STATUS_FILE")" ]; then
    log_info "Committing status update to git..."
    git add -f "$STATUS_FILE" 2>&1 | sed 's/^/  /' || true
    git commit -m "Update node health status: $ALERT_LEVEL" -m "Status: $ALERT_MESSAGE" --no-verify 2>&1 | sed 's/^/  /' || true

    log_info "Pushing to GitHub (will trigger monitoring workflow)..."
    git push origin main 2>&1 | sed 's/^/  /' || true

    log_success "Status published to GitHub Actions"
    echo -e "  ${GRAY}→ GitHub will create/update issue for status changes${NC}"
else
    log_info "No status changes detected, skipping git commit"
fi

# Cleanup
log_info "Cleaning up temporary files..."
rm -f "$TEMP_LOG"

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ "$ALERT_LEVEL" = "critical" ]; then
    echo -e "${RED}${BOLD}  [CRITICAL] Check notifications for details${NC}"
elif [ "$ALERT_LEVEL" = "warning" ]; then
    echo -e "${YELLOW}${BOLD}  [WARNING] Monitor node status closely${NC}"
else
    echo -e "${GREEN}${BOLD}  [OK] All systems operational${NC}"
fi
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
