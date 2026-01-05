#!/bin/bash
# Staking Status Check
# Shows comprehensive staking information for educational purposes

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

echo "=================================================="
echo "           STAKING STATUS REPORT"
echo "=================================================="
echo ""

# Get baker address
BAKER_ADDRESS=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    show address ${BAKER_ALIAS} 2>/dev/null | grep Hash: | awk '{print $2}')

echo "Baker: ${BAKER_ALIAS}"
echo "Address: ${BAKER_ADDRESS}"
echo ""

# Get balances from octez-client
echo "--- BALANCE BREAKDOWN ---"
echo ""

echo -n "Total Balance: "
docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning || echo "Error fetching balance"

echo -n "Full Balance (includes staked): "
docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get full balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning || echo "Error fetching balance"

echo -n "Staked Balance: "
docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get staked balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning || echo "Error fetching balance"

echo ""
echo "--- DELEGATION INFO ---"
echo ""

echo -n "Delegated to: "
docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get delegate for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning || echo "Not delegated"

echo ""
echo "--- NETWORK DATA (via RPC) ---"
echo ""

# Get detailed info from RPC
curl -s http://${RPC_ADDR}:${RPC_PORT}/chains/main/blocks/head/context/contracts/${BAKER_ADDRESS} 2>/dev/null | jq '{
  balance,
  "staked_balance": (.balance | tonumber),
  counter
}' 2>/dev/null || echo "Error fetching RPC data"

echo ""
echo "--- DELEGATE STATUS (via RPC) ---"
echo ""

# Get delegate-specific info
curl -s http://${RPC_ADDR}:${RPC_PORT}/chains/main/blocks/head/context/delegates/${BAKER_ADDRESS} 2>/dev/null | jq '{
  deactivated,
  grace_period,
  staking_balance,
  frozen_deposits,
  frozen_deposits_limit,
  delegated_contracts: (.delegated_contracts | length),
  total_delegated_stake
}' 2>/dev/null || echo "Error: Not registered as delegate or RPC unavailable"

echo ""
echo "--- STAKING REQUIREMENTS ---"
echo ""
echo "Minimum stake for baking rights: 6,000 ꜩ"
echo "Recommended for testnet: Stake all available funds"
echo ""

# Check if staked
STAKED_BALANCE=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get staked balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning | awk '{print $1}')

if [ "$STAKED_BALANCE" = "0" ]; then
    echo "⚠️  WARNING: Zero staked balance detected!"
    echo "    You will not receive baking/attesting rights."
    echo ""
    echo "    To stake funds, run:"
    echo "    npm run stake:all        # Stake all funds"
    echo "    npm run stake:minimum    # Stake 6,000 XTZ"
    echo "    npm run stake:custom     # Custom amount"
    echo ""
else
    echo "✅ Staked balance detected: ${STAKED_BALANCE} ꜩ"
    echo "   Baking rights will be assigned in ~5-7 cycles (14-21 days)"
    echo ""
fi

echo "=================================================="
echo ""
echo "For more commands:"
echo "  npm run stake:balance    # Quick staked balance check"
echo "  npm run account:balance  # Quick total balance check"
echo "  npm run stake:all        # Stake all funds"
echo "  npm run unstake:all      # Unstake all funds"
echo ""
