#!/bin/bash
# Stake Funds Script
# Educational tool for understanding Tezos staking
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

# Colors for educational output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=================================================="
echo "           TEZOS STAKING TOOL (STUDY MODE)"
echo "=================================================="
echo ""

# Get current balances
echo "📊 Fetching current balances..."
echo ""

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

echo "Current Balance Breakdown:"
echo "  Full Balance:    ${FULL_BALANCE} ꜩ"
echo "  Liquid Balance:  ${LIQUID_BALANCE} ꜩ (available to stake)"
echo "  Staked Balance:  ${STAKED_BALANCE} ꜩ (already staked)"
echo ""

# Calculate available to stake (liquid - small fee buffer)
AVAILABLE=$(echo "$LIQUID_BALANCE - 0.1" | bc)

if (( $(echo "$AVAILABLE <= 0" | bc -l) )); then
    echo -e "${RED}❌ Error: No liquid balance available to stake${NC}"
    echo "   You need liquid XTZ to stake. Current liquid: ${LIQUID_BALANCE} ꜩ"
    exit 1
fi

echo -e "${BLUE}💡 EDUCATION: Why Staking Matters${NC}"
echo "   Tezos uses Proof-of-Stake consensus."
echo "   Baking/attesting rights are assigned proportionally to STAKED balance."
echo "   Without staking, you won't receive any rights, even if you have XTZ."
echo ""
echo "   Process: Stake → Wait 5-7 cycles → Receive rights → Earn rewards"
echo ""

# Determine stake amount
MODE=${1:-interactive}
STAKE_AMOUNT=""

case $MODE in
    all)
        # Leave 0.5 XTZ for fees
        STAKE_AMOUNT=$(echo "$LIQUID_BALANCE - 0.5" | bc)
        echo -e "${GREEN}Mode: Stake ALL funds${NC}"
        echo "   Will stake: ${STAKE_AMOUNT} ꜩ"
        echo "   Reserved for fees: 0.5 ꜩ"
        ;;

    half)
        STAKE_AMOUNT=$(echo "$LIQUID_BALANCE / 2" | bc)
        echo -e "${YELLOW}Mode: Stake HALF of liquid funds${NC}"
        echo "   Will stake: ${STAKE_AMOUNT} ꜩ"
        echo "   Remaining liquid: $(echo "$LIQUID_BALANCE - $STAKE_AMOUNT" | bc) ꜩ"
        ;;

    minimum)
        STAKE_AMOUNT=6000
        echo -e "${BLUE}Mode: Stake MINIMUM (6,000 XTZ)${NC}"
        echo "   Will stake: ${STAKE_AMOUNT} ꜩ"
        echo "   This is the minimum for baking rights"

        if (( $(echo "$LIQUID_BALANCE < 6000" | bc -l) )); then
            echo -e "${RED}❌ Error: Insufficient balance${NC}"
            echo "   Need: 6,000 ꜩ"
            echo "   Have: ${LIQUID_BALANCE} ꜩ"
            exit 1
        fi
        ;;

    interactive)
        echo -e "${YELLOW}📝 Interactive Mode${NC}"
        echo ""
        echo "Available presets:"
        echo "  1) All funds       ($(echo "$LIQUID_BALANCE - 0.5" | bc) ꜩ)"
        echo "  2) Half funds      ($(echo "$LIQUID_BALANCE / 2" | bc) ꜩ)"
        echo "  3) Minimum stake   (6,000 ꜩ)"
        echo "  4) Custom amount"
        echo ""
        read -p "Choose an option (1-4): " CHOICE

        case $CHOICE in
            1)
                STAKE_AMOUNT=$(echo "$LIQUID_BALANCE - 0.5" | bc)
                ;;
            2)
                STAKE_AMOUNT=$(echo "$LIQUID_BALANCE / 2" | bc)
                ;;
            3)
                STAKE_AMOUNT=6000
                if (( $(echo "$LIQUID_BALANCE < 6000" | bc -l) )); then
                    echo -e "${RED}❌ Error: Insufficient balance for minimum stake${NC}"
                    exit 1
                fi
                ;;
            4)
                read -p "Enter amount to stake (in ꜩ): " STAKE_AMOUNT
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
        ;;

    *)
        # Assume it's a custom amount
        STAKE_AMOUNT=$MODE
        echo -e "${BLUE}Mode: Custom amount${NC}"
        echo "   Will stake: ${STAKE_AMOUNT} ꜩ"
        ;;
esac

# Validate amount
if (( $(echo "$STAKE_AMOUNT <= 0" | bc -l) )); then
    echo -e "${RED}❌ Error: Invalid stake amount: ${STAKE_AMOUNT}${NC}"
    exit 1
fi

if (( $(echo "$STAKE_AMOUNT > $LIQUID_BALANCE" | bc -l) )); then
    echo -e "${RED}❌ Error: Insufficient liquid balance${NC}"
    echo "   Requested: ${STAKE_AMOUNT} ꜩ"
    echo "   Available: ${LIQUID_BALANCE} ꜩ"
    exit 1
fi

echo ""
echo "=================================================="
echo "             STAKING SUMMARY"
echo "=================================================="
echo ""
echo "Account: ${BAKER_ALIAS}"
echo ""
echo "Before staking:"
echo "  Liquid:  ${LIQUID_BALANCE} ꜩ"
echo "  Staked:  ${STAKED_BALANCE} ꜩ"
echo ""
echo "After staking:"
echo "  Liquid:  $(echo "$LIQUID_BALANCE - $STAKE_AMOUNT" | bc) ꜩ"
echo "  Staked:  $(echo "$STAKED_BALANCE + $STAKE_AMOUNT" | bc) ꜩ"
echo ""
echo "Amount to stake: ${STAKE_AMOUNT} ꜩ"
echo ""

# Show educational info about the process
echo -e "${BLUE}📚 What happens when you stake:${NC}"
echo ""
echo "1. Your liquid XTZ becomes 'staked' (frozen)"
echo "2. Staked XTZ cannot be spent immediately"
echo "3. In 5-7 cycles (~14-21 days), you'll receive baking/attesting rights"
echo "4. Your baker will automatically use these rights to earn rewards"
echo "5. To unstake: 'npm run unstake:all' → wait 4 cycles → 'npm run unstake:finalize'"
echo ""

# Confirmation
if [ "$MODE" != "interactive" ]; then
    read -p "Do you want to proceed? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ] && [ "$CONFIRM" != "y" ]; then
        echo "Staking cancelled."
        exit 0
    fi
fi

echo ""
echo "🔄 Executing stake operation..."
echo ""

# Execute stake command
docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    stake ${STAKE_AMOUNT} for ${BAKER_ALIAS}

echo ""
echo -e "${GREEN}✅ Staking operation submitted!${NC}"
echo ""

# Wait a moment for the operation to be included
echo "⏳ Waiting 10 seconds for operation to be included in a block..."
sleep 10

# Show new balances
echo ""
echo "📊 Updated balances:"
echo ""

NEW_STAKED=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get staked balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning)

NEW_LIQUID=$(docker exec ${CONTAINER_PREFIX}-node \
    octez-client -d /var/run/tezos/node/.tezos-client \
    --endpoint http://${RPC_ADDR}:${RPC_PORT} \
    get balance for ${BAKER_ALIAS} 2>/dev/null | grep -v Warning)

echo "  Liquid:  ${NEW_LIQUID}"
echo "  Staked:  ${NEW_STAKED}"
echo ""

echo "=================================================="
echo "              NEXT STEPS"
echo "=================================================="
echo ""
echo "1. ✅ Funds are now staked"
echo "2. ⏳ Wait 5-7 cycles (14-21 days) for baking rights assignment"
echo "3. 📊 Monitor progress:"
echo "     npm run stake:status        # Check staking status"
echo "     npm run baker:rights        # Check for baking rights"
echo "     npm run delegate:status     # Check delegate status"
echo ""
echo "4. 🔍 Track on blockchain explorer:"
echo "     https://ghostnet.tzkt.io/$(docker exec ${CONTAINER_PREFIX}-node octez-client -d /var/run/tezos/node/.tezos-client show address ${BAKER_ALIAS} 2>/dev/null | grep Hash: | awk '{print $2}')"
echo ""
echo "5. 📈 Once you have rights, your baker will automatically:"
echo "     - Attest blocks (every ~10 seconds when you have rights)"
echo "     - Bake blocks (when selected by the protocol)"
echo "     - Earn testnet rewards"
echo ""
echo -e "${YELLOW}💡 Educational Note:${NC}"
echo "   On mainnet, staking locks up real XTZ worth real money."
echo "   Always test on testnet (like Ghostnet) first to understand the mechanics."
echo "   Unstaking has a 4-cycle delay (~12 days) before funds become liquid again."
echo ""
echo "=================================================="
echo ""
