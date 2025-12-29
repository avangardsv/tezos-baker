#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TEZOS BAKER - POST-REBOOT STARTUP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Load environment
if [ -f .env ]; then
    set -a
    source <(grep -v '^#' .env | sed -e '/^\s*$/d' -e "s/^\([^=]*\)=\(.*\)$/\1=\"\2\"/" -e 's/=""/=/g')
    set +a
else
    echo "❌ Error: .env file not found"
    echo "   Run: cp .env.example .env"
    exit 1
fi

CONTAINER="${CONTAINER_PREFIX:-tezos}-node"
BAKER_CONTAINER="${CONTAINER_PREFIX:-tezos}-baker"

echo "📋 STEP 1: Clean up stopped containers"
echo "────────────────────────────────────────────────────────────"
docker rm -f "$CONTAINER" 2>/dev/null && echo "  Removed old tezos-node container" || echo "  No old node container to remove"
docker rm -f "$BAKER_CONTAINER" 2>/dev/null && echo "  Removed old tezos-baker container" || echo "  No old baker container to remove"
echo ""

echo "🚀 STEP 2: Starting Tezos node"
echo "────────────────────────────────────────────────────────────"
docker run -d --name "$CONTAINER" \
  --entrypoint octez-node \
  -v "$PWD/${DATA_DIR:-data}:/var/run/tezos/node" \
  -p ${RPC_PORT:-8732}:${RPC_PORT:-8732} \
  -p ${P2P_PORT:-9732}:${P2P_PORT:-9732} \
  -p ${METRICS_PORT:-9095}:${METRICS_PORT:-9095} \
  tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} \
  run --network ${TEZOS_NETWORK:-ghostnet} --data-dir /var/run/tezos/node

if [ $? -eq 0 ]; then
    echo "  ✅ Tezos node started successfully"
else
    echo "  ❌ Failed to start tezos node"
    exit 1
fi
echo ""

echo "⏳ STEP 3: Waiting for node to initialize (10 seconds)..."
echo "────────────────────────────────────────────────────────────"
sleep 10
echo "  ✅ Done"
echo ""

echo "🔍 STEP 4: Checking node status"
echo "────────────────────────────────────────────────────────────"
RPC_ENDPOINT="http://${RPC_ADDR:-127.0.0.1}:${RPC_PORT:-8732}"

# Check if RPC is responding
if curl -s --max-time 5 "$RPC_ENDPOINT/chains/main/blocks/head/header" > /dev/null 2>&1; then
    LEVEL=$(curl -s "$RPC_ENDPOINT/chains/main/blocks/head/header" | jq -r '.level')
    echo "  ✅ Node is running"
    echo "  Current block: $LEVEL"
else
    echo "  ⚠️  Node is starting up, RPC not ready yet"
    echo "     This is normal, give it a few more seconds"
fi
echo ""

echo "🔧 STEP 5: Checking RPC ACL configuration"
echo "────────────────────────────────────────────────────────────"
# Check if config.json has ACL configured
if ! grep -q '"acl"' "${DATA_DIR:-data}/config.json" 2>/dev/null; then
    echo "  ⚠️  ACL not found in config.json - adding it now"
    echo "     (This is needed for baker to access /monitor/bootstrapped endpoint)"

    # Backup current config
    cp "${DATA_DIR:-data}/config.json" "${DATA_DIR:-data}/config.json.bak"

    # Add ACL using jq
    jq '.rpc.acl = [{"address": "0.0.0.0", "blacklist": []}]' "${DATA_DIR:-data}/config.json" > "${DATA_DIR:-data}/config.json.tmp"
    mv "${DATA_DIR:-data}/config.json.tmp" "${DATA_DIR:-data}/config.json"

    echo "  ✅ ACL configuration added - restarting node to apply"
    docker restart "$CONTAINER" > /dev/null
    sleep 5
else
    echo "  ✅ ACL configuration present"
fi
echo ""

echo "🎲 STEP 6: Checking for baking rights"
echo "────────────────────────────────────────────────────────────"
sleep 2  # Give RPC a bit more time

BAKER_ADDR=$(docker exec "$CONTAINER" octez-client -d /var/run/tezos/node/.tezos-client --endpoint "$RPC_ENDPOINT" show address ${BAKER_ALIAS:-alice} 2>/dev/null | grep "Hash:" | awk '{print $2}')

if [ -n "$BAKER_ADDR" ]; then
    RIGHTS=$(curl -s "$RPC_ENDPOINT/chains/main/blocks/head/helpers/baking_rights?delegate=$BAKER_ADDR&max_round=10" 2>/dev/null)
    RIGHTS_COUNT=$(echo "$RIGHTS" | jq '. | length' 2>/dev/null || echo "0")

    if [ "$RIGHTS_COUNT" -gt 0 ]; then
        echo "  ✅ You have baking rights!"
        echo ""
        echo "🔥 STEP 7: Starting baker"
        echo "────────────────────────────────────────────────────────────"

        docker run -d --name "$BAKER_CONTAINER" \
          --network "container:$CONTAINER" \
          -v "$PWD/${DATA_DIR:-data}:/var/run/tezos/node" \
          -v "$PWD/${DATA_DIR:-data}/.tezos-client:/home/tezos/.tezos-client" \
          --entrypoint "octez-baker-${PROTOCOL:-PtSeouLo}" \
          tezos/tezos:${OCTEZ_VERSION:-octez-v23.1} \
          run with local node /var/run/tezos/node --without-dal --liquidity-baking-toggle-vote pass ${BAKER_ALIAS:-alice}

        if [ $? -eq 0 ]; then
            echo "  ✅ Baker started successfully"
        else
            echo "  ❌ Failed to start baker"
        fi
    else
        echo "  ⏳ No baking rights yet"
        echo "     Baker not started (not needed until you have rights)"
        echo ""
        echo "     Run 'npm run baker:status' to check when you'll get rights"
    fi
else
    echo "  ⚠️  Could not check baking rights (node still starting)"
    echo "     Baker not started yet"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ STARTUP COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Running containers:"
docker ps --filter "name=${CONTAINER_PREFIX:-tezos}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "📊 Useful commands:"
echo "   npm run monitor          # Check node status"
echo "   npm run baker:status     # Check baker registration"
echo "   npm run node:logs        # View node logs"
echo "   npm run baker:logs       # View baker logs (if running)"
echo ""
