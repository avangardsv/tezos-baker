#!/bin/bash
# Live log monitoring with structured output (shows only new logs)
# Format: [timestamp] [level] message

# Load environment
if [ -f .env ]; then
    set -a
    source <(grep -v '^#' .env | sed -e '/^\s*$/d' -e "s/^\([^=]*\)=\(.*\)$/\1=\"\2\"/" -e 's/=""/=/g')
    set +a
fi

CONTAINER="${CONTAINER_PREFIX:-tezos}-node"
LOG_DIR="logs"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_DIR/monitor-$TIMESTAMP.log"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

echo "Tezos Node Log Monitor (Live)"
echo "Format: [timestamp] [level] message"
echo "Levels: INFO, WARN, ERROR"
echo "Showing only NEW logs (history skipped)"
echo "Logging to: $LOG_FILE"
echo "Press Ctrl+C to stop"
echo "----------------------------------------"

# Follow logs with structured filtering (live only, skip history)
docker logs -f --tail 0 "$CONTAINER" 2>&1 | grep --line-buffered -E "(synchronizing|received new head|too few connections|disconnected|error|warning|ERROR|WARN)" | while read line; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if echo "$line" | grep -q "synchronizing"; then
        level=$(echo "$line" | sed -n 's/.*level: \([0-9]*\).*/\1/p')
        age=$(echo "$line" | sed -n 's/.*head is \([^(]*\).*/\1/p')
        echo "[$timestamp] [INFO] sync: level=$level lag=$age"

    elif echo "$line" | grep -q "received new head"; then
        level=$(echo "$line" | sed -n 's/.*level \([0-9]*\).*/\1/p')
        echo "[$timestamp] [INFO] block: level=$level"

    elif echo "$line" | grep -q "too few connections"; then
        conn=$(echo "$line" | sed -n 's/.*conn\.: \([0-9]*\).*/\1/p')
        target=$(echo "$line" | sed -n 's/.*min\. target: \([0-9]*\).*/\1/p')
        echo "[$timestamp] [WARN] peers: active=$conn target=$target"

    elif echo "$line" | grep -q "insufficient history"; then
        peer=$(echo "$line" | sed -n 's/.*peer \([a-zA-Z0-9]*\).*/\1/p')
        echo "[$timestamp] [WARN] peer_rejected: id=$peer reason=insufficient_history"

    elif echo "$line" | grep -qi "error"; then
        msg=$(echo "$line" | sed 's/.*│ //' | sed 's/  */ /g')
        echo "[$timestamp] [ERROR] $msg"

    elif echo "$line" | grep -qi "warn"; then
        msg=$(echo "$line" | sed 's/.*│ //' | sed 's/  */ /g')
        echo "[$timestamp] [WARN] $msg"
    fi
done | tee -a "$LOG_FILE"
