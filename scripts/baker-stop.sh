#!/usr/bin/env bash
# Stop baker with automatic log backup

set -e

# Load environment
if [ -f .env ]; then
    set -a
    source <(grep -v '^#' .env | sed -e '/^\s*$/d' -e "s/^\([^=]*\)=\(.*\)$/\1=\"\2\"/" -e 's/=""/=/g')
    set +a
fi

CONTAINER="${CONTAINER_PREFIX:-tezos}-baker"
LOG_DIR="logs"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_DIR/baker-$TIMESTAMP.log"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo "📝 Saving baker logs to: $LOG_FILE"
    
    # Save logs (both stdout and stderr)
    docker logs "$CONTAINER" > "$LOG_FILE" 2>&1
    
    # Get log file size for feedback
    LOG_SIZE=$(du -h "$LOG_FILE" | awk '{print $1}')
    echo "✅ Saved $LOG_SIZE of logs"
    
    # Stop and remove container
    echo "🛑 Stopping baker container..."
    docker rm -f "$CONTAINER" > /dev/null
    echo "✅ Baker stopped"
else
    echo "ℹ️  Baker container not running (nothing to stop)"
fi
