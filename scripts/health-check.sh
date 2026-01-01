#!/bin/bash
# Node health check script - runs every 10 minutes
# Collects metrics and pushes status to GitHub for Actions monitoring

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Log helpers
log_info() {
    echo -e "${GRAY}$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')${NC} ${BLUE}INFO${NC}  $1"
}

log_warn() {
    echo -e "${GRAY}$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')${NC} ${YELLOW}WARN${NC}  $1"
}

log_error() {
    echo -e "${GRAY}$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')${NC} ${RED}ERROR${NC} $1"
}

log_success() {
    echo -e "${GRAY}$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')${NC} ${GREEN}SUCCESS${NC} $1"
}

# Load environment
if [ -f .env ]; then
    set -a
    source <(grep -v '^#' .env | sed -e '/^\s*$/d' -e "s/^\([^=]*\)=\(.*\)$/\1=\"\2\"/" -e 's/=""/=/g')
    set +a
fi

CONTAINER="${CONTAINER_PREFIX:-tezos}-node"
RPC_ENDPOINT="http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}"
STATUS_FILE="logs/node-status.json"
TEMP_LOG="/tmp/tezos-health-check.log"

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

# Get current peer count from RPC
log_info "Fetching network metrics..."
PEERS=$(curl -s "$RPC_ENDPOINT/network/connections" 2>/dev/null | jq 'length // 0' 2>/dev/null || echo "0")

# Get timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo ""
echo -e "${BOLD}METRICS SUMMARY${NC}"
echo -e "────────────────────────────────────────────────────────────"
printf "  %-25s %s\n" "Network Peers:" "${PEERS}/36"
printf "  %-25s %s\n" "Errors (10min):" "${ERROR_COUNT}"
printf "  %-25s %s\n" "Warnings (10min):" "${WARN_COUNT}"
echo ""

# Determine alert level based on actual node health
ALERT_LEVEL="healthy"
ALERT_MESSAGE="Node operating normally"
SEVERITY="OK"
COLOR="${GREEN}"

# Check for critical conditions
if [ "$PEERS" -eq 0 ]; then
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
