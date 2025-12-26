#!/bin/bash
# Register as delegate using direct RPC calls (bypasses octez-client bootstrap check)

set -e

BAKER_ALIAS="${1:-alice}"
RPC="http://127.0.0.1:8732"

echo "Registering $BAKER_ALIAS as delegate using direct RPC..."

# Get account info
docker exec tezos-node octez-client -d /var/run/tezos/node/.tezos-client show address "$BAKER_ALIAS" > /tmp/baker_info.txt
BAKER_ADDR=$(grep "Hash:" /tmp/baker_info.txt | awk '{print $2}')
echo "Baker address: $BAKER_ADDR"

# Get counter
COUNTER=$(curl -s "$RPC/chains/main/blocks/head/context/contracts/$BAKER_ADDR/counter" | jq -r '.')
NEXT_COUNTER=$((COUNTER + 1))
echo "Current counter: $COUNTER, Next: $NEXT_COUNTER"

# Get branch
BRANCH=$(curl -s "$RPC/chains/main/blocks/head/hash" | jq -r '.')
echo "Branch: $BRANCH"

# Forge delegation operation
FORGE_REQUEST=$(cat <<EOF
{
  "branch": "$BRANCH",
  "contents": [
    {
      "kind": "delegation",
      "source": "$BAKER_ADDR",
      "fee": "400",
      "counter": "$NEXT_COUNTER",
      "gas_limit": "1000",
      "storage_limit": "0",
      "delegate": "$BAKER_ADDR"
    }
  ]
}
EOF
)

echo "Forging operation..."
FORGED=$(curl -s -X POST "$RPC/chains/main/blocks/head/helpers/forge/operations" \
  -H "Content-Type: application/json" \
  -d "$FORGE_REQUEST" | jq -r '.')

echo "Forged operation: $FORGED"

# Sign the operation
echo "Signing operation..."
SIGNED=$(docker exec tezos-node octez-client -d /var/run/tezos/node/.tezos-client sign bytes "0x03$FORGED" for "$BAKER_ALIAS" | grep Signature: | awk '{print $2}')
echo "Signature: $SIGNED"

# Inject the operation
SIGNED_OP="${FORGED}${SIGNED}"
echo "Injecting operation..."
OP_HASH=$(curl -s -X POST "$RPC/injection/operation" \
  -H "Content-Type: application/json" \
  -d "\"$SIGNED_OP\"" | jq -r '.')

echo ""
echo "✅ Operation injected successfully!"
echo "Operation hash: $OP_HASH"
echo ""
echo "Check status:"
echo "  curl -s http://127.0.0.1:8732/chains/main/blocks/head/context/delegates/$BAKER_ADDR | jq '{deactivated, grace_period}'"
