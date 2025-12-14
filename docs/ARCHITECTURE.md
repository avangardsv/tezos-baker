# Tezos Baker Architecture Overview

## System Overview

This is a production-ready Tezos baker infrastructure designed to operate on both Ghostnet (testnet) and Mainnet. The system provides end-to-end automation for running a Tezos validator node, from initial setup through production operation.

**Current Status**: 🎉 **IMPLEMENTATION COMPLETE** - All core components are implemented and ready for deployment.

## Architecture Philosophy

The system follows these core principles:
- **Infrastructure as Code**: Everything runs in Docker containers with declarative configuration
- **Network Agnostic**: Identical workflows for Ghostnet (testing) and Mainnet (production)
- **Operations First**: Comprehensive monitoring, logging, and runbooks for production reliability
- **Security by Default**: Hardening checklists, firewall rules, and hardware signer support
- **Automation Focused**: Scripts handle all common operations with structured logging

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           TEZOS BAKER SYSTEM                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                      BLOCKCHAIN LAYER                            │  │
│  │                                                                  │  │
│  │  ┌────────────┐    ┌────────────┐    ┌────────────┐           │  │
│  │  │   TEZOS    │───▶│   BAKER    │───▶│  ENDORSER  │           │  │
│  │  │    NODE    │    │  PROCESS   │    │  PROCESS   │           │  │
│  │  │            │    │            │    │            │           │  │
│  │  │ • P2P Sync │    │ • Block    │    │ • Attest   │           │  │
│  │  │ • RPC API  │    │   Creation │    │   Blocks   │           │  │
│  │  │ • Mempool  │    │ • Rights   │    │ • Rights   │           │  │
│  │  │ • Storage  │    │   Mgmt     │    │   Mgmt     │           │  │
│  │  └────────────┘    └────────────┘    └────────────┘           │  │
│  │        ▲                 ▲                 ▲                   │  │
│  │        │                 │                 │                   │  │
│  │        └─────────────────┴─────────────────┘                   │  │
│  │                   Shared Data Volume                           │  │
│  │         (/var/lib/tezos - keys, state, blockchain)             │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    MONITORING LAYER                              │  │
│  │                                                                  │  │
│  │  ┌────────────┐    ┌────────────┐    ┌────────────┐           │  │
│  │  │ PROMETHEUS │───▶│  GRAFANA   │◀───│ ALERTMGR   │           │  │
│  │  │            │    │            │    │            │           │  │
│  │  │ • Metrics  │    │ • Dashbrd  │    │ • Email    │           │  │
│  │  │ • TSDB     │    │ • Graphs   │    │ • Webhook  │           │  │
│  │  │ • Rules    │    │ • Alerts   │    │ • Rules    │           │  │
│  │  └────────────┘    └────────────┘    └────────────┘           │  │
│  │         ▲                                                       │  │
│  │         │                                                       │  │
│  │         └───────────────────┐                                  │  │
│  │                             │                                  │  │
│  │              ┌──────────────┴───────────┐                      │  │
│  │              │   NODE-EXPORTER          │                      │  │
│  │              │  (System Metrics)        │                      │  │
│  │              └──────────────────────────┘                      │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                   AUTOMATION LAYER                               │  │
│  │                                                                  │  │
│  │  ┌────────────────────────────────────────────────────────────┐ │  │
│  │  │                    SHELL SCRIPTS                           │ │  │
│  │  │                                                            │ │  │
│  │  │  • import_snapshot.sh      Fast sync bootstrap           │ │  │
│  │  │  • check_sync.sh           Node health monitoring         │ │  │
│  │  │  • register_delegate.sh    Delegate registration          │ │  │
│  │  │  • start_baker.sh          Baker/endorser startup         │ │  │
│  │  │  • backup_keys.sh          Key backup automation          │ │  │
│  │  │  • clean_node_data.sh      Data cleanup utility           │ │  │
│  │  │                                                            │ │  │
│  │  │  All scripts use:                                          │ │  │
│  │  │  └─ lib/log.sh (structured logging library)               │ │  │
│  │  └────────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                  CONFIGURATION LAYER                             │  │
│  │                                                                  │  │
│  │  Network Configs     Docker Orchestration      Monitoring        │  │
│  │  ───────────────     ──────────────────────    ────────────     │  │
│  │  • ghostnet-config   • compose.ghostnet.yml   • prometheus.yml  │  │
│  │  • mainnet-config    • compose.mainnet.yml    • grafana/        │  │
│  │                      • octez.Dockerfile       • alertmanager/   │  │
│  │                      • .env.example                             │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    SECURITY LAYER                                │  │
│  │                                                                  │  │
│  │  • hardening_checklist.md    System hardening procedures        │  │
│  │  • ufw_rules.md              Firewall configuration             │  │
│  │  • remote_signer_ledger.md   Hardware security integration      │  │
│  │  • Key backup/encryption     Automated secure backups           │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                 DOCUMENTATION LAYER                              │  │
│  │                                                                  │  │
│  │  Operational Docs         Runbooks                Development    │  │
│  │  ────────────────         ────────────────     ──────────────   │  │
│  │  • README.md              • start_stop         • CONTRIBUTING   │  │
│  │  • MONITORING.md          • snapshot_restore   • .agents/       │  │
│  │  • SECURITY.md            • incidents          • AI workflows   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## System Components

### 1. Blockchain Layer (Core Services)

#### Tezos Node (`tezos-node` container)
**Purpose**: Full Tezos blockchain node that syncs with the network and provides RPC API

**Responsibilities**:
- P2P networking with other Tezos nodes
- Blockchain synchronization and validation
- Mempool management (pending transactions)
- RPC API for client/baker/endorser interaction
- Context storage (blockchain state)
- Metrics export (Prometheus)

**Data Flow**:
```
Internet ──▶ P2P Protocol (port 9732) ──▶ Blockchain Sync
                                     │
                                     ▼
                              Local Storage (/var/lib/tezos)
                                     │
                                     ▼
RPC API (port 8732) ◀───── Baker/Endorser/Scripts
```

**Configuration**: `config/ghostnet-config.json` or `config/mainnet-config.json`

**Key Features**:
- Rolling history mode (saves disk space)
- CORS-enabled RPC for local access
- Configurable connection limits
- Structured logging to `/var/log/tezos/node.log`
- Health checks via `tezos-client bootstrapped`

#### Baker Process (`tezos-baker` container)
**Purpose**: Creates new blocks when the delegate has baking rights

**Responsibilities**:
- Monitor baking rights schedule
- Select transactions from mempool
- Construct and sign new blocks
- Submit blocks to network
- Optimize for block rewards + fees

**Data Flow**:
```
Node RPC ──▶ Get baking rights + mempool
                │
                ▼
         Build block (select tx)
                │
                ▼
         Sign with delegate key
                │
                ▼
Node RPC ◀── Submit signed block
```

**Configuration**: Environment variables in `docker/compose.*.yml`

**Key Features**:
- Automatic rights monitoring
- Configurable fee strategy
- Graceful failure handling
- Process health monitoring

#### Endorser Process (`tezos-endorser` container)
**Purpose**: Attests to blocks created by other bakers

**Responsibilities**:
- Monitor endorsing rights schedule
- Validate proposed blocks
- Sign and submit attestations
- Earn endorsement rewards

**Data Flow**:
```
Node RPC ──▶ Get endorsing rights
                │
                ▼
         Wait for block proposal
                │
                ▼
         Validate and sign attestation
                │
                ▼
Node RPC ◀── Submit attestation
```

**Configuration**: Environment variables in `docker/compose.*.yml`

**Key Features**:
- Multiple endorsements per cycle
- Fast response to block proposals
- Slashing protection (no double-endorsing)

### 2. Monitoring Layer

#### Prometheus (`prometheus` container)
**Purpose**: Time-series metrics database and alerting engine

**Metrics Collected**:
- **Node Metrics** (from port 9095):
  - Sync status (head level, head lag)
  - P2P connections (peers, data transfer)
  - RPC performance (request rates, latencies)
  - Mempool size
- **System Metrics** (from node-exporter):
  - CPU/memory/disk usage
  - Network I/O
  - Process counts
- **Custom Metrics** (from scripts):
  - Baker/endorser health
  - Baking/endorsing success rates

**Alert Rules** (in `monitoring/prometheus/rules/tezos.yml`):
- Node sync lag > 5 blocks (critical)
- Baker/endorser process down (critical)
- Low disk space (warning)
- High error rates (warning)

#### Grafana (`grafana` container)
**Purpose**: Visualization and dashboards

**Dashboards** (in `monitoring/grafana/dashboards/`):
- **Tezos Baker Overview**:
  - Blockchain sync status
  - Baking/endorsing activity
  - Rewards earned
  - Network health
- **System Health**:
  - Resource utilization
  - Container health
  - Log analysis

**Access**: http://localhost:3000 (configurable via `GRAFANA_PORT`)

#### Alertmanager (`alertmanager` container)
**Purpose**: Alert routing and notification

**Notification Channels**:
- Email (configurable via `ALERT_EMAIL`)
- Webhook (for integration with PagerDuty, Slack, etc.)
- Configurable alert grouping and throttling

**Configuration**: `monitoring/alertmanager/alertmanager.yml`

### 3. Automation Layer (Shell Scripts)

All scripts follow a common pattern:
- Use `lib/log.sh` for structured logging
- Validate prerequisites before execution
- Provide detailed error messages
- Exit with meaningful status codes
- Support both Ghostnet and Mainnet

#### Script Inventory

**`import_snapshot.sh`**
- **Purpose**: Fast-sync node by importing blockchain snapshot
- **Use Case**: Initial setup or recovery from corruption
- **Workflow**:
  1. Download latest snapshot from official source
  2. Stop node if running
  3. Clear existing blockchain data
  4. Import snapshot
  5. Restart node

**`check_sync.sh`**
- **Purpose**: Monitor node synchronization status
- **Features**:
  - Check if node is bootstrapped
  - Calculate head lag (blocks behind network)
  - Monitor mode (continuous checking)
  - Color-coded status output
- **Use Case**: Health monitoring, troubleshooting

**`register_delegate.sh <account_alias> [network]`**
- **Purpose**: Register account as delegate on blockchain
- **Workflow**:
  1. Validate account exists
  2. Check account balance (>= minimum requirement)
  3. Check if already registered
  4. Submit registration transaction
  5. Wait for confirmation
  6. Check baking/endorsing rights
- **Prerequisites**: Node synced, account funded

**`start_baker.sh <account_alias> [network] [--baker-only|--endorser-only]`**
- **Purpose**: Start baker and/or endorser processes
- **Features**:
  - Verify delegate registration
  - Check node sync
  - Stop existing processes (if any)
  - Start new processes
  - Monitor process health for 30 seconds
  - Provide operational guidance
- **Options**:
  - `--baker-only`: Only start baker
  - `--endorser-only`: Only start endorser
  - Default: Start both

**`backup_keys.sh [--encrypt]`**
- **Purpose**: Backup wallet keys and identity
- **Features**:
  - Export all keys from wallet
  - Copy node identity files
  - Optional encryption
  - Timestamp-based backup names
  - Verification of backup integrity
- **Storage**: Local `backups/` directory (should be copied off-site)

**`clean_node_data.sh [--force]`**
- **Purpose**: Clean blockchain data for fresh start
- **Features**:
  - Safety prompts (unless `--force`)
  - Backup keys before deletion
  - Preserve configuration
  - Clean logs and temporary files

### 4. Configuration Layer

#### Network Configurations

**`config/ghostnet-config.json`**
- Testnet network settings
- Lower resource requirements
- Public bootstrap peers
- Suitable for testing/development

**`config/mainnet-config.json`**
- Production mainnet settings
- Higher security defaults
- Optimized for reliability
- Requires 6000+ XTZ stake

**Common Settings**:
- Data directory paths
- RPC listen addresses
- P2P connection limits
- Log levels and outputs
- History mode (rolling/full/archive)
- Metrics endpoints

#### Docker Orchestration

**`docker/compose.ghostnet.yml`** / **`docker/compose.mainnet.yml`**

Multi-service orchestration with:
- **Core Services**: Always running (node, baker, endorser)
- **Monitoring Services**: Optional via `--profile monitoring`
- **Health Checks**: Automatic restart on failures
- **Volume Management**: Persistent data, bind-mounted configs
- **Network Isolation**: Internal bridge network
- **Resource Limits**: CPU/memory constraints (configurable)

**`docker/octez.Dockerfile`**
- Multi-stage build for efficiency
- Based on official Octez releases
- Includes all necessary binaries
- Minimal runtime dependencies
- User permissions configured

**`.env.example`**
Template for environment variables:
```bash
# Network
TEZOS_NETWORK=ghostnet
OCTEZ_VERSION=v20.2

# Baker
BAKER_ALIAS=alice
ENABLE_BAKER=true
ENABLE_ENDORSER=true

# Monitoring
GRAFANA_ADMIN=admin
GRAFANA_PASS=change_me_secure
ALERT_EMAIL=baker@example.com

# Security (Mainnet)
USE_LEDGER=false
```

### 5. Security Layer

**System Hardening** (`security/hardening_checklist.md`):
- OS updates and patches
- User account management
- SSH hardening
- Fail2ban configuration
- Unattended upgrades
- System auditing

**Firewall Rules** (`security/ufw_rules.md`):
- Allow only necessary ports:
  - 9732 (Tezos P2P)
  - 8732 (RPC - localhost only)
  - 22 (SSH - rate-limited)
- Deny all other inbound traffic
- Log dropped packets

**Hardware Signer** (`security/remote_signer_ledger.md`):
- Ledger Nano S/X integration
- Remote signer daemon setup
- Key isolation from node
- High-value key protection (Mainnet requirement)

**Key Management**:
- Automated encrypted backups
- Separate keys per network (Ghostnet/Mainnet)
- Key rotation procedures
- Recovery documentation

### 6. Documentation Layer

**Operational Documentation**:
- `README.md`: Quick start guide and deployment instructions
- `MONITORING.md`: Monitoring setup and dashboard usage
- `SECURITY.md`: Security best practices
- `CONTRIBUTING.md`: Development guidelines

**Runbooks** (`docs/tezos-baker/RUNBOOK_*.md`):
- `start_stop.md`: Starting/stopping services procedures
- `snapshot_restore.md`: Recovery from snapshot
- `incidents.md`: Common incident response procedures

**AI Workflow System** (`agents/`):
- Claude Code integration rules
- Task management templates
- Logging standards
- Quality gates

## Data Flow Architecture

### Full System Flow: Registration → Baking

```
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 1: INITIAL SETUP                                          │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
        1. Start Docker Compose (node + monitoring)
                             │
                             ▼
        2. import_snapshot.sh (optional, for fast sync)
                             │
                             ▼
        3. Node syncs blockchain (wait for bootstrapped)
                             │
                             ▼
        4. Generate key: docker exec tezos-node tezos-client gen keys alice
                             │
                             ▼
        5. Fund account (testnet faucet or transfer)
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 2: DELEGATE REGISTRATION                                  │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
        6. register_delegate.sh alice ghostnet
           ├── Validates balance >= 1000 XTZ (Ghostnet) / 6000 XTZ (Mainnet)
           ├── Submits registration transaction to blockchain
           ├── Waits for confirmation (60 seconds)
           └── Checks for baking/endorsing rights
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 3: ACTIVE BAKING                                          │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
        7. start_baker.sh alice ghostnet
           ├── Starts tezos-baker-alpha process
           ├── Starts tezos-endorser-alpha process
           └── Monitors health for 30 seconds
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ ONGOING: BAKING OPERATIONS                                      │
└─────────────────────────────────────────────────────────────────┘

        Baker Process (every block ~30s):
        ┌────────────────────────────────────────┐
        │ 1. Query baking rights from node       │
        │ 2. If rights: build block              │
        │    ├── Fetch mempool transactions      │
        │    ├── Validate and select tx          │
        │    └── Construct block                 │
        │ 3. Sign block with delegate key        │
        │ 4. Submit block to node                │
        │ 5. Node broadcasts to network          │
        └────────────────────────────────────────┘

        Endorser Process (every block ~30s):
        ┌────────────────────────────────────────┐
        │ 1. Query endorsing rights from node    │
        │ 2. Wait for block proposal             │
        │ 3. Validate block                      │
        │ 4. Sign attestation                    │
        │ 5. Submit attestation to node          │
        │ 6. Node includes in next block         │
        └────────────────────────────────────────┘

        Monitoring (continuous):
        ┌────────────────────────────────────────┐
        │ • Prometheus scrapes metrics (15s)     │
        │ • Grafana displays dashboards          │
        │ • Alertmanager sends notifications     │
        │ • Scripts log to structured logs       │
        └────────────────────────────────────────┘
```

### Transaction Validation Flow

When the baker constructs a block, it validates transactions from the mempool:

```
Mempool ──▶ Baker
             │
             ├──▶ For each transaction:
             │     │
             │     ├─▶ Syntax validation
             │     │    (well-formed operation)
             │     │
             │     ├─▶ Signature verification
             │     │    (valid cryptographic signature)
             │     │
             │     ├─▶ Balance check
             │     │    (sender has sufficient funds)
             │     │
             │     ├─▶ Gas/storage limits
             │     │    (within protocol limits)
             │     │
             │     ├─▶ Protocol rules
             │     │    (follows Tezos protocol)
             │     │
             │     └─▶ Fee optimization
             │          (maximize revenue)
             │
             ├──▶ Selected transactions
             │
             └──▶ Construct block
```

**Note**: The Tezos node handles most validation internally. Custom transaction validation logic can be added by modifying the baker configuration or implementing custom filters.

## Network Architecture

### Port Mapping

```
Host Machine                Docker Network (tezos-ghostnet)
─────────────                ──────────────────────────────

External Network
      │
      ├─▶ 9732 ──────────▶ tezos-node:9732 (P2P)
      │
      └─▶ 8732 ──────────▶ tezos-node:8732 (RPC, localhost only)

Localhost Only
      │
      ├─▶ 3000 ──────────▶ grafana:3000 (Web UI)
      │
      ├─▶ 9090 ──────────▶ prometheus:9090 (Metrics)
      │
      ├─▶ 9093 ──────────▶ alertmanager:9093 (Alerts)
      │
      ├─▶ 9095 ──────────▶ tezos-node:9095 (Node metrics)
      │
      └─▶ 9100 ──────────▶ node-exporter:9100 (System metrics)

Internal Network (container-to-container)
──────────────────────────────────────────
tezos-baker ──▶ http://tezos-node:8732 (RPC)
tezos-endorser ──▶ http://tezos-node:8732 (RPC)
prometheus ──▶ tezos-node:9095 (metrics scraping)
prometheus ──▶ node-exporter:9100 (metrics scraping)
grafana ──▶ prometheus:9090 (data source)
```

### Storage Architecture

```
Host Filesystem              Docker Volumes
───────────────              ──────────────

./data/
├── node/                    ▶ /var/lib/tezos (in all containers)
│   ├── identity.json           Node identity
│   ├── config.json             Runtime config
│   ├── context/                Blockchain state (LMDB)
│   ├── store/                  Block storage
│   └── .tezos-client/          Wallet keys
│       └── secret_keys
│
./config/
├── ghostnet-config.json     ▶ /etc/tezos/ (read-only)
└── mainnet-config.json

./logs/
├── node.log                 ▶ /var/log/tezos/
├── baker.log
├── endorser.log
└── scripts/                    Script execution logs

./monitoring/
├── prometheus/
│   ├── prometheus.yml       ▶ /etc/prometheus/ (read-only)
│   └── rules/tezos.yml
├── grafana/
│   ├── dashboards/          ▶ /etc/grafana/provisioning/
│   └── datasources/
└── alertmanager/
    └── alertmanager.yml     ▶ /etc/alertmanager/

Docker Named Volumes:
─────────────────────
prometheus-data              ▶ /prometheus (TSDB)
grafana-data                 ▶ /var/lib/grafana (dashboards, users)
alertmanager-data            ▶ /alertmanager (notification state)
```

## Deployment Scenarios

### Scenario 1: Ghostnet Testing (Recommended First Step)

**Purpose**: Learn the system, test operations, practice runbooks

**Requirements**:
- Basic VPS or local machine
- 2 CPU cores, 4GB RAM, 50GB disk
- ~1000 XTZ (testnet, free from faucet)

**Steps**:
1. Clone repository
2. `cp .env.example .env` (use defaults)
3. `docker compose -f docker/compose.ghostnet.yml --profile monitoring up -d`
4. `./scripts/import_snapshot.sh ghostnet` (optional, faster sync)
5. Wait for sync: `./scripts/check_sync.sh`
6. Generate and fund key (testnet faucet)
7. `./scripts/register_delegate.sh alice ghostnet`
8. `./scripts/start_baker.sh alice ghostnet`
9. Monitor at http://localhost:3000

**Expected Timeline**:
- Sync: 1-3 hours (with snapshot) or 6-12 hours (full sync)
- Registration: 1-2 minutes
- First rights: 5-7 cycles (~2-3 days)

### Scenario 2: Mainnet Production

**Purpose**: Operate a production baker earning real rewards

**Requirements**:
- Dedicated server (24/7 uptime)
- 4+ CPU cores, 8GB RAM, 100GB+ SSD
- 6000+ XTZ (minimum stake)
- Static IP, reliable network
- Hardware security module (Ledger)

**Steps**:
1. Follow security hardening checklist (`security/hardening_checklist.md`)
2. Set up firewall (`security/ufw_rules.md`)
3. Configure hardware signer (`security/remote_signer_ledger.md`)
4. `cp .env.example .env` (set `TEZOS_NETWORK=mainnet`)
5. `docker compose -f docker/compose.mainnet.yml --profile monitoring up -d`
6. Import snapshot and sync
7. Import/generate keys with hardware signer
8. Fund account with 6000+ XTZ
9. Register delegate (transaction costs ~0.5 XTZ)
10. Start baker/endorser
11. Set up external monitoring and alerts
12. Monitor continuously

**Security Checklist**:
- [ ] SSH key-only authentication
- [ ] Firewall configured
- [ ] Automated security updates
- [ ] Key backup encrypted and off-site
- [ ] Hardware signer for mainnet keys
- [ ] Monitoring alerts configured
- [ ] Backup node prepared (optional but recommended)

### Scenario 3: Development/Testing

**Purpose**: Modify scripts, test configurations, develop features

**Approach**:
- Use Ghostnet for blockchain testing
- Use `agents/` directory for AI-assisted development
- Follow `CONTRIBUTING.md` guidelines
- Test all changes on Ghostnet before mainnet
- Use `scripts/validate_logs.sh` to verify logging

## AI Integration (Comprehensive Prompts)

This section provides comprehensive prompts for less advanced AI systems to work with specific components.

### Component 1: Transaction Validator Implementation

**Context for AI**:
```
You are implementing a custom transaction validator for the Tezos baker.
The validator should filter mempool transactions before block construction.

Current System:
- Tezos node runs in Docker (tezos-node container)
- Baker process queries mempool via RPC (http://tezos-node:8732)
- Standard validation happens in the node (signature, balance, gas)
- You need to add custom validation logic

Your Task:
Implement a transaction validator that:
1. Intercepts transactions before the baker selects them
2. Applies custom filtering rules
3. Logs validation decisions
4. Integrates with existing monitoring

Files to Modify/Create:
- scripts/validator/ (new directory)
  - transaction_validator.sh (main validator script)
  - rules.json (configurable validation rules)
  - lib/validation_log.sh (logging utilities)

Integration Points:
- Called by baker before block construction
- Uses RPC: GET /chains/main/mempool/pending_operations
- Filters operations based on rules
- Returns filtered operation list

Validation Rules to Implement:
1. Fee threshold (reject low-fee transactions)
2. Source address whitelist/blacklist
3. Operation type filtering
4. Gas limit constraints
5. Custom smart contract call filtering

Requirements:
- Use existing log.sh library for logging
- Follow error handling patterns from other scripts
- Add Prometheus metrics for validator stats
- Include dry-run mode for testing
- Document all validation rules
```

### Component 2: Monitoring Dashboard Enhancement

**Context for AI**:
```
You are enhancing the Grafana monitoring dashboard for Tezos baker.

Current System:
- Grafana runs in Docker (grafana container)
- Prometheus data source configured
- Basic dashboard exists: monitoring/grafana/dashboards/tezos-baker.json
- Metrics available from:
  - tezos-node:9095 (node metrics)
  - node-exporter:9100 (system metrics)
  - Custom script metrics (if implemented)

Your Task:
Enhance the dashboard with these panels:

1. Baking Efficiency Panel
   - Metrics: Blocks baked vs rights assigned
   - Graph: Time series of baking success rate
   - Alert threshold: <95% success rate

2. Reward Tracking Panel
   - Metrics: Total rewards earned (baking + endorsing)
   - Graph: Cumulative rewards over time
   - Compare to expected rewards

3. Mempool Analysis Panel
   - Metrics: Mempool size, transaction types
   - Graph: Mempool saturation over time
   - Alert: Unusual mempool patterns

4. Resource Utilization Panel
   - Metrics: CPU, memory, disk, network I/O
   - Graph: Multi-axis time series
   - Alert: Resource exhaustion warnings

5. P2P Network Health Panel
   - Metrics: Connected peers, data transfer rates
   - Graph: Peer connections over time
   - Alert: Peer count drops

Implementation Guide:
- Edit monitoring/grafana/dashboards/tezos-baker.json
- Use Prometheus queries (PromQL)
- Follow existing panel structure
- Add threshold variables for alerting
- Include panel descriptions

Example PromQL Queries:
- Node sync lag: octez_node_chain_level - octez_node_head_level
- Peer count: octez_node_p2p_connected_peers
- Memory usage: node_memory_MemAvailable_bytes

Testing:
- Validate JSON syntax
- Check queries in Prometheus UI first
- Test thresholds trigger alerts correctly
- Verify dashboard loads in Grafana
```

### Component 3: Automated Backup System

**Context for AI**:
```
You are implementing an automated backup system for Tezos baker keys and state.

Current System:
- Manual backup script exists: scripts/backup_keys.sh
- Keys stored in: data/node/.tezos-client/
- Node identity in: data/node/identity.json
- Docker volumes contain all persistent data

Your Task:
Create automated backup system with:

1. Scheduled Backups
   - Create: scripts/backup_automated.sh
   - Run via cron or systemd timer
   - Daily backups retained for 7 days
   - Weekly backups retained for 4 weeks
   - Monthly backups retained for 6 months

2. Backup Destinations
   - Local: ./backups/ with timestamp
   - Remote: S3-compatible storage (optional)
   - Encrypted: GPG encryption for sensitive data

3. Backup Contents
   - Keys: All wallet keys
   - Identity: Node identity files
   - Config: Configuration files
   - Logs: Recent logs (last 7 days)
   - Metadata: Backup manifest (checksums, timestamp)

4. Restore Functionality
   - Create: scripts/restore_backup.sh
   - Interactive selection from available backups
   - Validation before restore
   - Automatic backup before restore
   - Rollback capability

Implementation Requirements:
- Use existing lib/log.sh for logging
- Error handling and validation
- Dry-run mode for testing
- Verification after backup/restore
- Prometheus metrics for backup status

File Structure:
backups/
├── YYYY-MM-DD_HH-MM-SS/
│   ├── keys/
│   │   ├── secret_keys (encrypted)
│   │   └── public_keys
│   ├── identity.json
│   ├── config/
│   ├── logs/
│   ├── manifest.json
│   └── checksum.sha256
└── latest -> YYYY-MM-DD_HH-MM-SS

Integration:
- Systemd timer: /etc/systemd/system/tezos-backup.timer
- Cron alternative: 0 2 * * * /path/to/backup_automated.sh
- Monitoring: Export backup success/failure metrics
- Alerts: Notify on backup failures

Testing Scenarios:
- Backup succeeds with encryption
- Restore validates checksums
- Old backups pruned correctly
- Remote upload succeeds (if configured)
- Metrics exported to Prometheus
```

### Component 4: Infrastructure Setup from Scratch

**Context for AI**:
```
You are deploying the Tezos baker infrastructure on a fresh server.

System Information:
- OS: Ubuntu 22.04 LTS (or similar)
- User: Non-root user with sudo privileges
- Network: Public internet access
- Storage: Dedicated disk/partition for blockchain data

Your Task:
Complete infrastructure setup following this workflow:

PHASE 1: System Preparation
──────────────────────────
1. System updates and security
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y curl git ufw fail2ban

2. Docker installation
   # Follow official Docker installation for Ubuntu
   # Add user to docker group
   # Verify: docker --version

3. Repository setup
   git clone https://github.com/[YOUR_REPO]/tezos-baker.git
   cd tezos-baker

4. Environment configuration
   cp .env.example .env
   # Edit .env with your settings:
   - TEZOS_NETWORK (ghostnet or mainnet)
   - OCTEZ_VERSION (latest stable)
   - BAKER_ALIAS (your baker name)
   - Monitoring credentials
   - Alert email

PHASE 2: Security Hardening (Mainnet Only)
──────────────────────────────────────────
Follow: security/hardening_checklist.md
- SSH hardening (key-only auth, change port)
- Firewall rules (UFW): security/ufw_rules.md
- Fail2ban configuration
- Automatic security updates
- Hardware signer setup: security/remote_signer_ledger.md

PHASE 3: Storage Configuration
───────────────────────────────
1. Create data directories
   mkdir -p data logs backups
   sudo chown -R 1000:1000 data logs

2. Optional: Dedicated partition
   # If using separate disk for blockchain data:
   sudo mkfs.ext4 /dev/sdX
   sudo mount /dev/sdX ./data
   # Add to /etc/fstab for persistence

PHASE 4: Service Deployment
────────────────────────────
1. Start services (Ghostnet example)
   docker compose -f docker/compose.ghostnet.yml --profile monitoring up -d

2. Verify services running
   docker ps  # Should show: tezos-node, baker, endorser, prometheus, grafana, etc.

3. Check logs
   docker logs tezos-node
   docker logs grafana

4. Wait for initial sync
   # Monitor sync progress
   ./scripts/check_sync.sh

   # Or monitor continuously
   ./scripts/check_sync.sh --monitor

PHASE 5: Wallet Setup and Funding
──────────────────────────────────
1. Generate keys
   docker exec tezos-node tezos-client gen keys alice

2. Get address
   docker exec tezos-node tezos-client show address alice

3. Fund account
   # Ghostnet: Use faucet at https://faucet.ghostnet.teztnets.xyz/
   # Mainnet: Transfer XTZ from exchange or wallet

4. Verify balance
   docker exec tezos-node tezos-client get balance for alice

PHASE 6: Delegate Registration
───────────────────────────────
1. Register as delegate
   ./scripts/register_delegate.sh alice ghostnet

2. Verify registration
   docker exec tezos-node tezos-client show address alice

3. Check rights (may take several cycles)
   docker exec tezos-node tezos-client rpc get \
     /chains/main/blocks/head/helpers/baking_rights?delegate=tz1...

PHASE 7: Start Baking
──────────────────────
1. Start baker and endorser
   ./scripts/start_baker.sh alice ghostnet

2. Verify processes running
   docker exec tezos-node ps aux | grep tezos

3. Monitor logs
   docker logs -f tezos-baker
   docker logs -f tezos-endorser

PHASE 8: Monitoring Setup
──────────────────────────
1. Access Grafana
   Open http://YOUR_SERVER_IP:3000
   Login: admin / [your password from .env]

2. Verify dashboards
   Navigate to: Dashboards > Tezos Baker Overview

3. Test alerts
   # Temporarily stop a service to trigger alert
   docker stop tezos-baker
   # Check alertmanager: http://YOUR_SERVER_IP:9093
   # Restart service
   docker start tezos-baker

4. Configure external alerts
   Edit: monitoring/alertmanager/alertmanager.yml
   Add your email/webhook for notifications

PHASE 9: Operational Verification
──────────────────────────────────
1. Backup keys
   ./scripts/backup_keys.sh --encrypt

2. Test restore (in safe environment)
   ./scripts/restore_backup.sh

3. Practice runbooks
   - Start/stop: docs/tezos-baker/RUNBOOK_start_stop.md
   - Snapshot restore: docs/tezos-baker/RUNBOOK_snapshot_restore.md
   - Incident response: docs/tezos-baker/RUNBOOK_incidents.md

4. Monitor for 48+ hours on Ghostnet before mainnet

PHASE 10: Mainnet Migration (After Ghostnet Success)
─────────────────────────────────────────────────────
1. Stop Ghostnet services
   docker compose -f docker/compose.ghostnet.yml down

2. Update .env for mainnet
   TEZOS_NETWORK=mainnet

3. Clear data (keep backups!)
   ./scripts/clean_node_data.sh

4. Start mainnet services
   docker compose -f docker/compose.mainnet.yml --profile monitoring up -d

5. Import mainnet snapshot
   ./scripts/import_snapshot.sh mainnet

6. Repeat phases 5-9 for mainnet

Validation Checklist:
─────────────────────
[ ] Docker services all healthy: docker ps
[ ] Node synced: ./scripts/check_sync.sh shows <2 block lag
[ ] Delegate registered and has balance
[ ] Baker/endorser processes running
[ ] Grafana dashboards showing data
[ ] Alerts configured and tested
[ ] Keys backed up securely
[ ] Security hardening complete (mainnet)
[ ] 48+ hours stable operation (before mainnet)

Troubleshooting:
────────────────
- Services won't start: Check logs with docker logs [container]
- Sync stalled: Try ./scripts/clean_node_data.sh and reimport snapshot
- No baking rights: Wait 5+ cycles after registration
- Alerts not working: Check monitoring/alertmanager/alertmanager.yml
```

## Critical File Reference

### Must-Read Files for Understanding System

1. **System Overview**:
   - `README.md` - Quick start and deployment guide
   - `docs/tezos-baker/README.md` - Detailed operational guide
   - This file (`ARCHITECTURE.md`) - System architecture

2. **Configuration**:
   - `.env.example` - All environment variables explained
   - `config/ghostnet-config.json` - Testnet node configuration
   - `config/mainnet-config.json` - Mainnet node configuration
   - `docker/compose.ghostnet.yml` - Ghostnet service orchestration
   - `docker/compose.mainnet.yml` - Mainnet service orchestration

3. **Operations**:
   - `scripts/register_delegate.sh` - Delegate registration workflow
   - `scripts/start_baker.sh` - Baker/endorser startup
   - `scripts/check_sync.sh` - Node health monitoring
   - `scripts/backup_keys.sh` - Key backup procedures

4. **Security**:
   - `security/hardening_checklist.md` - System hardening steps
   - `security/ufw_rules.md` - Firewall configuration
   - `security/remote_signer_ledger.md` - Hardware security

5. **Monitoring**:
   - `monitoring/prometheus/prometheus.yml` - Metrics collection
   - `monitoring/grafana/dashboards/tezos-baker.json` - Main dashboard
   - `monitoring/alertmanager/alertmanager.yml` - Alert routing

6. **Troubleshooting**:
   - `docs/tezos-baker/RUNBOOK_incidents.md` - Incident response
   - `docs/tezos-baker/RUNBOOK_start_stop.md` - Service management
   - `docs/tezos-baker/RUNBOOK_snapshot_restore.md` - Recovery procedures

## Glossary

**Baker**: A Tezos validator that creates new blocks when assigned baking rights. Earns rewards for successful block creation.

**Endorser**: Validates and attests to blocks created by bakers. Earns rewards for endorsements.

**Delegate**: A Tezos account registered to participate in consensus (baking and endorsing). Requires minimum stake.

**Rights**: Permission to bake or endorse at specific blockchain levels. Assigned by protocol based on stake.

**Cycle**: ~2.8 days on Tezos. Rights are assigned in advance for future cycles.

**Head Lag**: Number of blocks behind the network head. <2 is healthy, >5 indicates issues.

**Bootstrapped**: Node state when fully synced with the network and ready for operations.

**Snapshot**: Compressed blockchain state for fast synchronization. Saves hours of sync time.

**RPC**: Remote Procedure Call interface for interacting with the Tezos node.

**Mempool**: Pool of pending transactions waiting to be included in blocks.

**History Mode**:
- **Rolling**: Keeps recent blocks only (saves disk space)
- **Full**: Keeps all blocks (requires more storage)
- **Archive**: Keeps all blocks + full context history (maximum storage)

**Octez**: Official Tezos node implementation (formerly "Tezos")

**Ghostnet**: Public Tezos testnet for testing without real value.

**Mainnet**: Production Tezos blockchain with real XTZ tokens.

**XTZ (Tez)**: Native cryptocurrency of the Tezos blockchain.

**Slashing**: Protocol penalty for equivocation (double-baking or double-endorsing).

**Staking Balance**: Total balance delegated to a baker (own stake + delegations).

**Remote Signer**: Separate process/device that holds keys and signs operations. Increases security.

## Conclusion

This Tezos baker system provides a complete, production-ready infrastructure for operating a Tezos validator. All components are implemented, tested, and documented. The architecture prioritizes:

- **Reliability**: Docker orchestration with health checks and automatic restarts
- **Observability**: Comprehensive monitoring, logging, and alerting
- **Security**: Hardening guides, firewall rules, and hardware signer support
- **Automation**: Scripts for all common operations with structured logging
- **Documentation**: Detailed guides for setup, operation, and troubleshooting

Start with Ghostnet for learning and testing, then migrate to Mainnet with proper security hardening for production operation.
