#!/bin/bash
set -e

# Load environment
if [ -f .env ]; then
    set -a
    source <(grep -v '^#' .env | sed -e '/^\s*$/d' -e "s/^\([^=]*\)=\(.*\)$/\1=\"\2\"/" -e 's/=""/=/g')
    set +a
fi

BAKER_ALIAS="${BAKER_ALIAS:-alice}"
RPC_ENDPOINT="http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}"
CONTAINER="${CONTAINER_PREFIX:-tezos}-node"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  BAKER STATUS CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get baker address
echo "📋 BAKER ACCOUNT"
echo "────────────────────────────────────────────────────────────"
BAKER_INFO=$(docker exec "$CONTAINER" octez-client --endpoint "$RPC_ENDPOINT" show address "$BAKER_ALIAS" 2>&1 | grep -v "Warning" | grep -v "NOT the Tezos" | grep -v "Do NOT use")
BAKER_ADDR=$(echo "$BAKER_INFO" | grep "Hash:" | awk '{print $2}')
echo "  Alias:   $BAKER_ALIAS"
echo "  Address: $BAKER_ADDR"
echo ""

# Get balance
BALANCE=$(docker exec "$CONTAINER" octez-client --endpoint "$RPC_ENDPOINT" get balance for "$BAKER_ALIAS" 2>&1 | grep -v "Warning" | grep -v "NOT the Tezos" | grep -v "Do NOT use" | tr -d '\n')
echo "  Balance: $BALANCE"
echo ""

# Get current cycle info
echo "📅 BLOCKCHAIN STATUS"
echo "────────────────────────────────────────────────────────────"
METADATA=$(curl -s "$RPC_ENDPOINT/chains/main/blocks/head/metadata")
CURRENT_LEVEL=$(echo "$METADATA" | jq -r '.level_info.level')
CURRENT_CYCLE=$(echo "$METADATA" | jq -r '.level_info.cycle')
CYCLE_POSITION=$(echo "$METADATA" | jq -r '.level_info.cycle_position')
echo "  Current level:    $CURRENT_LEVEL"
echo "  Current cycle:    $CURRENT_CYCLE"
echo "  Cycle position:   $CYCLE_POSITION / ~8192 blocks"
echo ""

# Get delegate status
echo "🏛️  DELEGATE STATUS"
echo "────────────────────────────────────────────────────────────"
DELEGATE_DATA=$(curl -s "$RPC_ENDPOINT/chains/main/blocks/head/context/delegates/$BAKER_ADDR" 2>/dev/null)

if [ $? -eq 0 ] && [ "$DELEGATE_DATA" != "null" ]; then
    DEACTIVATED=$(echo "$DELEGATE_DATA" | jq -r '.deactivated')
    GRACE_PERIOD=$(echo "$DELEGATE_DATA" | jq -r '.grace_period')
    BAKING_POWER=$(echo "$DELEGATE_DATA" | jq -r '.baking_power')
    TOTAL_DELEGATED=$(echo "$DELEGATE_DATA" | jq -r '.total_delegated')
    OWN_STAKED=$(echo "$DELEGATE_DATA" | jq -r '.own_staked')

    # Convert from mutez to tez
    TOTAL_DELEGATED_TEZ=$(echo "scale=6; $TOTAL_DELEGATED / 1000000" | bc)
    BAKING_POWER_TEZ=$(echo "scale=6; $BAKING_POWER / 1000000" | bc)
    OWN_STAKED_TEZ=$(echo "scale=6; $OWN_STAKED / 1000000" | bc)

    if [ "$DEACTIVATED" = "false" ]; then
        echo "  ✅ Registered:     YES"
        echo "  ✅ Active:         YES"
    else
        echo "  ❌ Registered:     YES"
        echo "  ❌ Active:         NO (deactivated)"
    fi

    echo "  Grace period:     Cycle $GRACE_PERIOD"
    echo ""
    echo "  Total delegated:  $TOTAL_DELEGATED_TEZ ꜩ"
    echo "  Own staked:       $OWN_STAKED_TEZ ꜩ"
    echo "  Baking power:     $BAKING_POWER_TEZ ꜩ"

    if [ "$BAKING_POWER" = "0" ]; then
        echo ""
        echo "  ⚠️  NO BAKING POWER YET"
        echo "      Baking rights assigned ~5 cycles after registration"
        echo "      Expected in cycle $(($CURRENT_CYCLE + 5)) or later"
    fi
else
    echo "  ❌ NOT REGISTERED as delegate"
    echo ""
    echo "  To register, run:"
    echo "    npm run delegate:register"
fi

echo ""

# Check for baking rights
echo "🎲 BAKING RIGHTS"
echo "────────────────────────────────────────────────────────────"
RIGHTS=$(curl -s "$RPC_ENDPOINT/chains/main/blocks/head/helpers/baking_rights?delegate=$BAKER_ADDR&max_round=10" 2>/dev/null)
RIGHTS_COUNT=$(echo "$RIGHTS" | jq '. | length')

if [ "$RIGHTS_COUNT" -gt 0 ]; then
    echo "  ✅ YOU HAVE BAKING RIGHTS!"
    echo ""
    echo "  Next $RIGHTS_COUNT baking opportunities:"
    echo "$RIGHTS" | jq -r '.[] | "    Level \(.level) - Round \(.round) - \(.estimated_time)"' | head -5

    # Check if baker is running
    echo ""
    echo "🔥 BAKER CONTAINER"
    echo "────────────────────────────────────────────────────────────"
    if docker ps | grep -q "${CONTAINER_PREFIX:-tezos}-baker"; then
        echo "  ✅ Baker is RUNNING"
    else
        echo "  ❌ Baker is NOT running"
        echo ""
        echo "  Start baker with:"
        echo "    npm run baker:start"
    fi
else
    echo "  ⏳ No baking rights in next blocks"
    echo ""
    echo "  This is normal if you just registered."
    echo "  Baking rights are assigned based on stake snapshots"
    echo "  taken ~5 cycles before the baking cycle."
    echo ""
    echo "  💡 Check again in a few days or after cycle $(($CURRENT_CYCLE + 5))"
fi

echo ""

# Check attestation rights (endorsement rights)
echo "✍️  ATTESTATION RIGHTS"
echo "────────────────────────────────────────────────────────────"
ATTEST_RIGHTS=$(curl -s "$RPC_ENDPOINT/chains/main/blocks/head/helpers/attestation_rights?delegate=$BAKER_ADDR" 2>/dev/null)
ATTEST_COUNT=$(echo "$ATTEST_RIGHTS" | jq '. | length')

if [ "$ATTEST_COUNT" -gt 0 ]; then
    echo "  ✅ YOU HAVE ATTESTATION RIGHTS!"
    echo ""
    echo "  Next attestation slots:"
    echo "$ATTEST_RIGHTS" | jq -r '.[] | "    Level \(.level) - \(.estimated_time)"' | head -5
else
    echo "  ⏳ No attestation rights yet"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Summary
if [ "$RIGHTS_COUNT" -gt 0 ]; then
    echo "✅ READY TO BAKE!"
    echo ""
    if ! docker ps | grep -q "${CONTAINER_PREFIX:-tezos}-baker"; then
        echo "⚠️  Remember to start the baker:"
        echo "   npm run baker:start"
    fi
else
    echo "⏳ WAITING FOR BAKING RIGHTS"
    echo ""
    echo "Your baker is registered correctly, but needs to wait for:"
    echo "  1. Stake snapshot (random block in current/next cycle)"
    echo "  2. ~5 cycle delay (~14 days on Ghostnet)"
    echo "  3. Rights calculation for future cycles"
    echo ""
    echo "Check status again later:"
    echo "  npm run baker:status"
fi
echo ""
