#!/bin/bash
# Staking Status Check

set -e

# Load environment
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

CONTAINER_PREFIX=${CONTAINER_PREFIX:-tezos}
RPC_ADDR=${RPC_ADDR:-127.0.0.1}
RPC_PORT=${RPC_PORT:-8732}
BAKER_ALIAS=${BAKER_ALIAS:-alice}

echo ""
echo "=== STAKING STATUS ==="
echo ""

# Get baker address
BAKER_ADDRESS=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    show address ${BAKER_ALIAS} 2>/dev/null | grep Hash: | awk '{print $2}')

echo "Baker: ${BAKER_ALIAS} (${BAKER_ADDRESS})"
echo ""

# Get balances
echo "Balances:"
LIQUID=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning | awk '{print $1}')

FULL=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get full balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning | awk '{print $1}')

STAKED=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get staked balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning | awk '{print $1}')

echo "  Liquid:  ${LIQUID} ꜩ (available to spend/stake)"
echo "  Staked:  ${STAKED} ꜩ (frozen for baking)"
echo "  Total:   ${FULL} ꜩ"
echo ""

# Check delegate status
echo "Delegation:"
DELEGATE=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get delegate for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning | head -1)
echo "  ${DELEGATE}"
echo ""

# RPC delegate info
echo "Network Status:"
curl -s http://${RPC_ADDR}:${RPC_PORT}/chains/main/blocks/head/context/delegates/${BAKER_ADDRESS} 2>/dev/null | jq -r '
  "  Deactivated: \(.deactivated // "null")",
  "  Grace period: \(.grace_period // "N/A")",
  "  Staking balance: \(.staking_balance // "0")",
  "  Frozen deposits: \(.frozen_deposits // "0")"
' 2>/dev/null || echo "  Unable to fetch delegate info (may not be registered)"

echo ""

# Status check
if [ "$STAKED" = "0" ]; then
    echo "⚠️  WARNING: Zero staked balance!"
    echo ""
    echo "You will NOT receive baking/attesting rights without staking."
    echo ""
    echo "Quick fix:"
    echo "  npm run stake:all        # Stake all funds"
    echo "  npm run stake:minimum    # Stake 6,000 XTZ"
    echo ""
else
    echo "✅ Staked: ${STAKED} ꜩ"
    echo ""
    echo "Rights will be assigned in ~14-21 days after first stake."
    echo "Check progress: npm run baker:rights"
    echo ""
fi

echo "Other commands:"
echo "  npm run stake:all         # Stake all available funds"
echo "  npm run stake:custom      # Stake custom amount"
echo "  npm run unstake:all       # Unstake all funds"
echo ""
