#!/bin/bash
# Stake Funds Script
# Usage: ./stake-funds.sh [all|half|minimum|<amount>]

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
echo "=== STAKE FUNDS ==="
echo ""

# Get current balances
FULL_BALANCE=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get full balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning | awk '{print $1}')

STAKED_BALANCE=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get staked balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning | awk '{print $1}')

LIQUID_BALANCE=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning | awk '{print $1}')

echo "Current balances:"
echo "  Liquid:  ${LIQUID_BALANCE} ꜩ"
echo "  Staked:  ${STAKED_BALANCE} ꜩ"
echo "  Total:   ${FULL_BALANCE} ꜩ"
echo ""

# Check if has liquid balance
AVAILABLE=$(echo "$LIQUID_BALANCE - 0.5" | bc)
if (( $(echo "$AVAILABLE <= 0" | bc -l) )); then
    echo "Error: No liquid balance available to stake"
    exit 1
fi

# Determine stake amount
MODE=${1:-interactive}
STAKE_AMOUNT=""

case $MODE in
    all)
        STAKE_AMOUNT=$(echo "$LIQUID_BALANCE - 0.5" | bc)
        echo "Mode: Stake ALL (${STAKE_AMOUNT} ꜩ, reserve 0.5 for fees)"
        ;;
    half)
        STAKE_AMOUNT=$(echo "$LIQUID_BALANCE / 2" | bc)
        echo "Mode: Stake HALF (${STAKE_AMOUNT} ꜩ)"
        ;;
    minimum)
        STAKE_AMOUNT=6000
        echo "Mode: Stake MINIMUM (${STAKE_AMOUNT} ꜩ)"
        if (( $(echo "$LIQUID_BALANCE < 6000" | bc -l) )); then
            echo "Error: Need 6,000 ꜩ, have ${LIQUID_BALANCE} ꜩ"
            exit 1
        fi
        ;;
    interactive)
        echo "Choose stake amount:"
        echo "  1) All funds       ($(echo "$LIQUID_BALANCE - 0.5" | bc) ꜩ)"
        echo "  2) Half funds      ($(echo "$LIQUID_BALANCE / 2" | bc) ꜩ)"
        echo "  3) Minimum         (6,000 ꜩ)"
        echo "  4) Custom amount"
        echo ""
        read -p "Choice (1-4): " CHOICE

        case $CHOICE in
            1) STAKE_AMOUNT=$(echo "$LIQUID_BALANCE - 0.5" | bc) ;;
            2) STAKE_AMOUNT=$(echo "$LIQUID_BALANCE / 2" | bc) ;;
            3) STAKE_AMOUNT=6000
               if (( $(echo "$LIQUID_BALANCE < 6000" | bc -l) )); then
                   echo "Error: Insufficient balance"
                   exit 1
               fi ;;
            4) read -p "Enter amount (ꜩ): " STAKE_AMOUNT ;;
            *) echo "Invalid choice"; exit 1 ;;
        esac
        ;;
    *)
        STAKE_AMOUNT=$MODE
        echo "Mode: Custom (${STAKE_AMOUNT} ꜩ)"
        ;;
esac

# Validate
if (( $(echo "$STAKE_AMOUNT <= 0" | bc -l) )); then
    echo "Error: Invalid amount: ${STAKE_AMOUNT}"
    exit 1
fi

if (( $(echo "$STAKE_AMOUNT > $LIQUID_BALANCE" | bc -l) )); then
    echo "Error: Insufficient balance (need ${STAKE_AMOUNT} ꜩ, have ${LIQUID_BALANCE} ꜩ)"
    exit 1
fi

echo ""
echo "Summary:"
echo "  Amount to stake: ${STAKE_AMOUNT} ꜩ"
echo "  After staking:"
echo "    Liquid: $(echo "$LIQUID_BALANCE - $STAKE_AMOUNT" | bc) ꜩ"
echo "    Staked: $(echo "$STAKED_BALANCE + $STAKE_AMOUNT" | bc) ꜩ"
echo ""
echo "Note: Staked funds are frozen. Rights assigned in ~14-21 days."
echo "      To unstake: npm run unstake:all → wait 12 days → npm run unstake:finalize"
echo ""

# Confirm
if [ "$MODE" != "interactive" ]; then
    read -p "Proceed? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ] && [ "$CONFIRM" != "y" ]; then
        echo "Cancelled"
        exit 0
    fi
fi

echo ""
echo "Staking ${STAKE_AMOUNT} ꜩ..."
echo ""

# Execute
docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    stake ${STAKE_AMOUNT} for ${BAKER_ALIAS}

echo ""
echo "✅ Stake operation submitted"
echo ""
echo "Waiting 10 seconds for confirmation..."
sleep 10

# Show new balances
NEW_STAKED=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get staked balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning)

NEW_LIQUID=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning)

echo ""
echo "New balances:"
echo "  Liquid:  ${NEW_LIQUID}"
echo "  Staked:  ${NEW_STAKED}"
echo ""
echo "Next steps:"
echo "  1. Check status: npm run stake:status"
echo "  2. Wait 14-21 days for baking rights"
echo "  3. Monitor: npm run baker:rights"
echo "  4. View on explorer: https://ghostnet.tzkt.io/$(docker exec ${CONTAINER_PREFIX}-node octez-client -d /var/run/tezos/node/.tezos-client show address ${BAKER_ALIAS} 2>/dev/null | grep Hash: | awk '{print $2}')"
echo ""
