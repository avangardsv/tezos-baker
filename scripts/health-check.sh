#!/bin/bash
# Node health check script - runs every 10 minutes
# Collects metrics and pushes status to GitHub for Actions monitoring

set -e

# Load environment
if [ -f .env ]; then
    set -a
    source <(grep -v '^#' .env | sed -e '/^\s*$/d' -e "s/^\([^=]*\)=\(.*\)$/\1=\"\2\"/" -e 's/=""/=/g')
    set +a
fi

CONTAINER="${CONTAINER_PREFIX:-tezos}-node"
STATUS_FILE="logs/node-status.json"
TEMP_LOG="/tmp/tezos-health-check.log"

# Create logs directory
mkdir -p logs

# Collect last 10 minutes of logs for analysis
docker logs --since 10m "$CONTAINER" 2>&1 > "$TEMP_LOG" || {
    echo "Failed to get docker logs"
    exit 1
}

# Count recent activity
ERROR_COUNT=$(grep -ci "error" "$TEMP_LOG" 2>/dev/null | tail -1 || echo "0")
WARN_COUNT=$(grep -ci "warn" "$TEMP_LOG" 2>/dev/null | tail -1 || echo "0")
LOG_LINES=$(wc -l < "$TEMP_LOG" | tr -d ' ')

# Get current peer count
PEERS=$(docker logs --tail 100 "$CONTAINER" 2>&1 | \
    grep -o "conn\.: [0-9]*" | \
    tail -1 | \
    grep -o "[0-9]*" || echo "0")

# Get timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Determine alert level
ALERT_LEVEL="healthy"
ALERT_MESSAGE="Node operating normally"

# Check for critical conditions
if [ "$LOG_LINES" -lt 5 ]; then
    ALERT_LEVEL="critical"
    ALERT_MESSAGE="Node appears stuck - no log activity"
elif [ "$ERROR_COUNT" -gt 50 ]; then
    ALERT_LEVEL="critical"
    ALERT_MESSAGE="High error rate detected ($ERROR_COUNT errors in 10min)"
elif [ "$PEERS" -lt 5 ]; then
    ALERT_LEVEL="critical"
    ALERT_MESSAGE="Very low peer count ($PEERS peers)"
# Check for warning conditions
elif [ "$ERROR_COUNT" -gt 20 ]; then
    ALERT_LEVEL="warning"
    ALERT_MESSAGE="Elevated error rate ($ERROR_COUNT errors in 10min)"
elif [ "$PEERS" -lt 10 ]; then
    ALERT_LEVEL="warning"
    ALERT_MESSAGE="Low peer count ($PEERS peers)"
fi

# Write status JSON
cat > "$STATUS_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "alert_level": "$ALERT_LEVEL",
  "alert_message": "$ALERT_MESSAGE",
  "peers": "$PEERS",
  "errors_last_10min": "$ERROR_COUNT",
  "warnings_last_10min": "$WARN_COUNT",
  "log_activity": "$LOG_LINES"
}
EOF

echo "Health check completed: $ALERT_LEVEL - $ALERT_MESSAGE"
echo "Status written to: $STATUS_FILE"

# Commit and push to trigger GitHub Actions
if [ -n "$(git status --porcelain "$STATUS_FILE")" ]; then
    git add "$STATUS_FILE"
    git commit -m "Update node health status: $ALERT_LEVEL" -m "Status: $ALERT_MESSAGE" --no-verify
    git push origin main
    echo "Status pushed to GitHub - Actions will process alert"
else
    echo "No status change - skipping commit"
fi

# Cleanup
rm -f "$TEMP_LOG"
