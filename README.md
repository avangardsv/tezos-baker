# Tezos Baker

Run a Tezos validator on Ghostnet testnet. Simple setup, minimal configuration.

## Installation

### Prerequisites

- **Docker** - Container runtime
- **Docker Compose** - Multi-container orchestration tool
- **System requirements**: 2+ CPU cores, 4GB RAM, 50GB disk space

### Install Docker (macOS)

**Option 1: Docker Desktop (Recommended)**
1. Download Docker Desktop from https://www.docker.com/products/docker-desktop
2. Install and launch Docker Desktop
3. Verify installation:
```bash
docker --version
docker compose version
```

**Option 2: Homebrew**
```bash
# Install Docker
brew install --cask docker

# Launch Docker Desktop application
# Verify installation
docker --version
docker compose version
```

### Setup

```bash
# Clone and navigate to repository
cd tezos-baker

# Create environment file
cp .env.example .env

# Start services
./scripts/setup.sh ghostnet
```

## Quick Start

Get your baker running in 3 commands:

```bash
# 1. Setup node
./scripts/setup.sh ghostnet

# 2. Generate keys and fund account
docker exec tezos-node octez-client gen keys alice
docker exec tezos-node octez-client show address alice
# Visit https://faucet.ghostnet.teztnets.xyz/ to fund your address

# 3. Start baking
./scripts/start.sh alice ghostnet
```

## Tutorial

### Step 1: Start the Node

```bash
./scripts/setup.sh ghostnet
```

This command:
- Creates necessary directories (`data/`, `logs/`)
- Starts Docker containers (node, baker, endorser)
- Begins blockchain synchronization

**Expected time**: 1-3 hours (with snapshot) or 6-12 hours (full sync)

### Step 2: Wait for Synchronization

```bash
./scripts/status.sh
```

Monitor until you see:
```
✓ Node is bootstrapped and synchronized
```

Watch continuously (macOS):
```bash
./scripts/monitor.sh
```

Or manually check periodically:
```bash
./scripts/status.sh
```

### Step 3: Create Your Account

```bash
# Generate key pair
docker exec tezos-node octez-client gen keys alice

# Get your address
docker exec tezos-node octez-client show address alice
```

Copy the `tz1...` address that appears.

### Step 4: Fund Your Account

1. Visit the [Ghostnet Faucet](https://faucet.ghostnet.teztnets.xyz/)
2. Paste your `tz1...` address
3. Request testnet XTZ (~6000 ꜩ)
4. Wait 1-2 minutes, then verify:

```bash
docker exec tezos-node octez-client get balance for alice
```

### Step 5: Start Baking

```bash
./scripts/start.sh alice ghostnet
```

This command:
- Registers your account as a delegate
- Starts the baker process
- Starts the endorser process

Verify it's running:
```bash
./scripts/status.sh
```

## Concepts

### What is Baking?

Baking is the process of creating new blocks on the Tezos blockchain. As a baker, you:
- **Bake blocks** when selected by the protocol
- **Endorse blocks** created by other bakers
- **Earn rewards** for successful operations

### Timeline

```
Setup (10 min)
  ↓
Node Sync (1-3 hours)
  ↓
Account Setup (5 min)
  ↓
Registration (1 min)
  ↓
Wait for Rights (~14-21 days)
  ↓
Start Baking & Earning
```

**Important**: You won't receive baking rights immediately. The protocol assigns rights based on stake over 5-7 cycles (~14-21 days).

### Testnet vs Mainnet

This setup is for **Ghostnet testnet only**:
- ✅ Tokens have no real value
- ✅ Safe to experiment
- ✅ Keys stored in container (fine for testnet)
- ❌ **NOT suitable for mainnet** (requires hardware wallet, security hardening)

## API Reference

### Scripts

#### `setup.sh [network]`

Starts the Tezos node and begins synchronization.

**Arguments:**
- `network` - `ghostnet` (default) or `mainnet`

**Example:**
```bash
./scripts/setup.sh ghostnet
```

#### `start.sh <account> [network]`

Registers account as delegate and starts baker/endorser.

**Arguments:**
- `account` - Account alias (e.g., `alice`)
- `network` - `ghostnet` (default) or `mainnet`

**Example:**
```bash
./scripts/start.sh alice ghostnet
```

#### `status.sh [network]`

Shows current status of node, baker, and endorser.

**Example:**
```bash
./scripts/status.sh
```

#### `stop.sh`

Stops all services gracefully.

**Example:**
```bash
./scripts/stop.sh
```

### Octez Client Commands

All commands run inside the `tezos-node` container:

```bash
# Generate keys
docker exec tezos-node octez-client gen keys <alias>

# Show address
docker exec tezos-node octez-client show address <alias>

# Check balance
docker exec tezos-node octez-client get balance for <alias>

# Register as delegate
docker exec tezos-node octez-client register key <alias> as delegate

# Check sync status
docker exec tezos-node octez-client bootstrapped

# Check baking rights
docker exec tezos-node octez-client rpc get \
  /chains/main/blocks/head/helpers/baking_rights
```

### Docker Commands

```bash
# View running containers
docker ps

# View logs
docker logs -f tezos-node
docker logs -f tezos-baker
docker logs -f tezos-endorser

# Restart service
docker compose restart tezos-node

# Stop all services
docker compose down
```

## Troubleshooting

### Node Won't Sync

**Symptoms**: `status.sh` shows "Node is not synchronized"

**Solutions**:
```bash
# Check node logs
docker logs tezos-node

# Restart node
docker compose restart tezos-node

# Check network connectivity
docker exec tezos-node netstat -tulpn | grep 9732
```

### Baker Won't Start

**Symptoms**: Baker container running but no process

**Common causes**:
1. Node not synced - wait for sync first
2. Delegate not registered - run `./scripts/start.sh` again
3. No baking rights yet - normal, wait 5+ cycles

**Check**:
```bash
docker logs tezos-baker
docker exec tezos-node octez-client show address alice
```

### No Funds

**Symptoms**: Balance shows 0

**Solution**:
- Request from [Ghostnet Faucet](https://faucet.ghostnet.teztnets.xyz/)
- Wait 1-2 minutes for transaction to confirm
- Verify: `docker exec tezos-node octez-client get balance for alice`

### Container Errors

**Symptoms**: Containers won't start

**Solutions**:
```bash
# Check Docker is running
docker info

# Rebuild containers
docker compose build

# Check logs
docker compose logs
```

## Resources

- **Testnet Faucet**: https://faucet.ghostnet.teztnets.xyz/
- **Block Explorer**: https://ghostnet.tzkt.io/
- **Octez Documentation**: https://tezos.gitlab.io/
- **Tezos Community**: https://tezos.com/community

## Next Steps

After your baker is running:

1. **Monitor operations**: Use `./scripts/status.sh` regularly
2. **Watch logs**: `docker logs -f tezos-baker`
3. **Track on explorer**: Search your address on [ghostnet.tzkt.io](https://ghostnet.tzkt.io/)
4. **Wait for rights**: First baking rights appear after ~14-21 days

---

**Ready to start?** Run `./scripts/setup.sh ghostnet` and follow the tutorial above.
