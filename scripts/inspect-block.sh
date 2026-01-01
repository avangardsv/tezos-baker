#!/usr/bin/env bash

# Block Inspector - Show what consists of a Tezos block

# Load environment variables
if [ -f .env ]; then
    set -a
    source <(grep -v '^#' .env | sed -e '/^\s*$/d' -e 's/^\([^=]*\)=\(.*\)$/\1="\2"/' -e 's/=""/=/g')
    set +a
fi

RPC_ENDPOINT="http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}"

BLOCK="${1:-head}"

echo "════════════════════════════════════════════════════════"
echo "  TEZOS BLOCK INSPECTOR"
echo "════════════════════════════════════════════════════════"
echo ""

# 1. BLOCK HEADER
echo "📋 BLOCK HEADER (Metadata)"
echo "────────────────────────────────────────────────────────"
HEADER=$(curl -s $RPC_ENDPOINT/chains/main/blocks/$BLOCK/header)

echo "$HEADER" | jq '{
  level: .level,
  hash: .hash,
  timestamp: .timestamp,
  protocol: .protocol,
  priority: .priority,
  validation_pass: .validation_pass,
  fitness: .fitness,
  context: .context,
  predecessor: .predecessor
}'

echo ""

# 2. OPERATIONS COUNT
echo "📦 OPERATIONS (Transactions & Activities)"
echo "────────────────────────────────────────────────────────"

# Get operations
OPS=$(curl -s $RPC_ENDPOINT/chains/main/blocks/$BLOCK/operations)

# Count by validation pass
ENDORSEMENTS=$(echo "$OPS" | jq '.[0] | length')
VOTES=$(echo "$OPS" | jq '.[1] | length')
ANONYMOUS=$(echo "$OPS" | jq '.[2] | length')
MANAGER=$(echo "$OPS" | jq '.[3] | length')

TOTAL_OPS=$((ENDORSEMENTS + VOTES + ANONYMOUS + MANAGER))

echo "Total Operations: $TOTAL_OPS"
echo ""
echo "  Pass 0 (Endorsements):   $ENDORSEMENTS operations"
echo "  Pass 1 (Votes):          $VOTES operations"
echo "  Pass 2 (Anonymous):      $ANONYMOUS operations"
echo "  Pass 3 (Manager):        $MANAGER operations"

echo ""

# 3. MANAGER OPERATIONS DETAILS
if [ "$MANAGER" -gt 0 ]; then
    echo "💼 MANAGER OPERATIONS BREAKDOWN"
    echo "────────────────────────────────────────────────────────"
    
    echo "$OPS" | jq -r '.[3] | .[] | .contents[] | 
        "  • \(.kind): " + 
        (if .source then (.source[0:10] + "...") else "N/A" end) + 
        (if .destination then " → " + (.destination[0:10] + "...") else "" end) +
        (if .amount then " (\(.amount) mutez)" else "" end)' | head -20
    
    if [ "$MANAGER" -gt 20 ]; then
        echo "  ... and $((MANAGER - 20)) more"
    fi
    echo ""
fi

# 4. BLOCK SIZE
echo "📊 BLOCK SIZE & PERFORMANCE"
echo "────────────────────────────────────────────────────────"

# Get metadata
METADATA=$(curl -s $RPC_ENDPOINT/chains/main/blocks/$BLOCK/metadata)

BAKER=$(echo "$METADATA" | jq -r '.baker // "N/A"')
CONSUMED_GAS=$(echo "$METADATA" | jq -r '.consumed_milligas // "0"')
CONSUMED_GAS_HUMAN=$((CONSUMED_GAS / 1000))

echo "  Baker:          ${BAKER:0:20}..."
echo "  Consumed Gas:   $CONSUMED_GAS_HUMAN gas"
echo "  Operations:     $TOTAL_OPS"

# Calculate approximate block size
BLOCK_JSON=$(curl -s $RPC_ENDPOINT/chains/main/blocks/$BLOCK)
BLOCK_SIZE=$(echo "$BLOCK_JSON" | wc -c | tr -d ' ')
BLOCK_SIZE_KB=$((BLOCK_SIZE / 1024))

echo "  Block Size:     ~${BLOCK_SIZE_KB}KB (JSON)"

echo ""

# 5. ENDORSEMENTS DETAILS
if [ "$ENDORSEMENTS" -gt 0 ]; then
    echo "✅ ENDORSEMENTS (Consensus Votes)"
    echo "────────────────────────────────────────────────────────"
    
    echo "$OPS" | jq -r '.[0] | .[] | .contents[] | 
        if .kind == "endorsement" then
            "  • Endorsement by " + (.metadata.delegate[0:20] + "...") + 
            " (slots: " + (.metadata.slots | tostring) + ")"
        else
            "  • \(.kind)"
        end' | head -10
    
    if [ "$ENDORSEMENTS" -gt 10 ]; then
        echo "  ... and $((ENDORSEMENTS - 10)) more"
    fi
    echo ""
fi

# 6. BLOCK CHAIN CONTEXT
echo "🔗 BLOCKCHAIN CONTEXT"
echo "────────────────────────────────────────────────────────"

PREDECESSOR=$(echo "$HEADER" | jq -r '.predecessor')
LEVEL=$(echo "$HEADER" | jq -r '.level')
TIMESTAMP=$(echo "$HEADER" | jq -r '.timestamp')

echo "  Current Block:    #$LEVEL"
echo "  Previous Block:   ${PREDECESSOR:0:30}..."
echo "  Block Time:       $TIMESTAMP"

# Get predecessor to calculate block time
if [ "$BLOCK" = "head" ]; then
    PREV_BLOCK=$(curl -s $RPC_ENDPOINT/chains/main/blocks/$(($LEVEL - 1))/header)
    PREV_TIME=$(echo "$PREV_BLOCK" | jq -r '.timestamp')
    
    if [ "$PREV_TIME" != "null" ]; then
        CURRENT_TS=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$TIMESTAMP" "+%s" 2>/dev/null)
        PREV_TS=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$PREV_TIME" "+%s" 2>/dev/null)
        BLOCK_INTERVAL=$((CURRENT_TS - PREV_TS))
        echo "  Block Interval:   ${BLOCK_INTERVAL}s (time since previous block)"
    fi
fi

echo ""

echo "════════════════════════════════════════════════════════"
echo "Block successfully inspected!"
echo ""
echo "💡 Usage: $0 <block_hash_or_level>"
echo "   Examples:"
echo "     $0 head                    # Current block"
echo "     $0 17035391                # Block by level"
echo "     $0 BLocqcR4bs...           # Block by hash"
echo "════════════════════════════════════════════════════════"
