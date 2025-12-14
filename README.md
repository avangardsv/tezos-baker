# Tezos Baker

Run a Tezos validator on Ghostnet testnet. Simple setup, minimal configuration.

## Installation

### Prerequisites

- **Podman** - Container runtime
- **podman-compose** - Compose tool for Podman
- **System requirements**: 2+ CPU cores, 4GB RAM, 50GB disk space

### Install Podman (macOS)

**First, install Homebrew if you don't have it:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Then install Podman:**
```bash
# Install Podman
brew install podman

# Initialize and start Podman machine
podman machine init
podman machine start

# Verify installation
podman --version
```

### Install podman-compose

```bash
# macOS/Linux - use pip3
pip3 install podman-compose

# If command not found, add to PATH (macOS)
echo 'export PATH="$HOME/Library/Python/3.9/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Or install via Homebrew (alternative)
brew install podman-compose
```

**Verify installation:**
```bash
podman-compose --version
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
podman exec tezos-node tezos-client gen keys alice
podman exec tezos-node tezos-client show address alice
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
- Starts Podman containers (node, baker, endorser)
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
podman exec tezos-node tezos-client gen keys alice

# Get your address
podman exec tezos-node tezos-client show address alice
```

Copy the `tz1...` address that appears.

### Step 4: Fund Your Account

1. Visit the [Ghostnet Faucet](https://faucet.ghostnet.teztnets.xyz/)
2. Paste your `tz1...` address
3. Request testnet XTZ (~6000 ꜩ)
4. Wait 1-2 minutes, then verify:

```bash
podman exec tezos-node tezos-client get balance for alice
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

### Tezos Client Commands

All commands run inside the `tezos-node` container:

```bash
# Generate keys
podman exec tezos-node tezos-client gen keys <alias>

# Show address
podman exec tezos-node tezos-client show address <alias>

# Check balance
podman exec tezos-node tezos-client get balance for <alias>

# Register as delegate
podman exec tezos-node tezos-client register key <alias> as delegate

# Check sync status
podman exec tezos-node tezos-client bootstrapped

# Check baking rights
podman exec tezos-node tezos-client rpc get \
  /chains/main/blocks/head/helpers/baking_rights
```

### Podman Commands

```bash
# View running containers
podman ps

# View logs
podman logs -f tezos-node
podman logs -f tezos-baker
podman logs -f tezos-endorser

# Restart service
podman-compose restart tezos-node

# Stop all services
podman-compose down
```

## Troubleshooting

### Node Won't Sync

**Symptoms**: `status.sh` shows "Node is not synchronized"

**Solutions**:
```bash
# Check node logs
podman logs tezos-node

# Restart node
podman-compose restart tezos-node

# Check network connectivity
podman exec tezos-node netstat -tulpn | grep 9732
```

### Baker Won't Start

**Symptoms**: Baker container running but no process

**Common causes**:
1. Node not synced - wait for sync first
2. Delegate not registered - run `./scripts/start.sh` again
3. No baking rights yet - normal, wait 5+ cycles

**Check**:
```bash
podman logs tezos-baker
podman exec tezos-node tezos-client show address alice
```

### No Funds

**Symptoms**: Balance shows 0

**Solution**:
- Request from [Ghostnet Faucet](https://faucet.ghostnet.teztnets.xyz/)
- Wait 1-2 minutes for transaction to confirm
- Verify: `podman exec tezos-node tezos-client get balance for alice`

### Container Errors

**Symptoms**: Containers won't start

**Solutions**:
```bash
# Check Podman is running
podman info

# Rebuild containers
podman-compose build

# Check logs
podman-compose logs
```

## Resources

- **Testnet Faucet**: https://faucet.ghostnet.teztnets.xyz/
- **Block Explorer**: https://ghostnet.tzkt.io/
- **Octez Documentation**: https://tezos.gitlab.io/
- **Tezos Community**: https://tezos.com/community

## Next Steps

After your baker is running:

1. **Monitor operations**: Use `./scripts/status.sh` regularly
2. **Watch logs**: `podman logs -f tezos-baker`
3. **Track on explorer**: Search your address on [ghostnet.tzkt.io](https://ghostnet.tzkt.io/)
4. **Wait for rights**: First baking rights appear after ~14-21 days

---

**Ready to start?** Run `./scripts/setup.sh ghostnet` and follow the tutorial above.
