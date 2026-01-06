# Anatomy of a Tezos Block

This document explains what data makes up a Tezos block and how to inspect it.

## Quick Inspection

```bash
# Inspect current block
npm run block:inspect

# Inspect specific block by level
npm run block:inspect 17035391

# Inspect by block hash
npm run block:inspect BLocqcR4bsD2RFLxwivqyAPupWJFAGDqfMW43rHf7xFNzxXZJqA
```

## What's in a Block?

A Tezos block consists of **4 main components**:

### 1. 📋 Block Header (Metadata)

The header contains essential blockchain metadata:

```json
{
  "level": 17035391,              // Block height/number
  "hash": "BLocqcR4bs...",        // Unique block identifier
  "timestamp": "2025-12-19T13:24:46Z",  // When block was created
  "protocol": "PtSeouLouX...",    // Current protocol version
  "validation_pass": 4,            // Number of operation validation passes
  "fitness": [...],                // Chain selection metric
  "context": "CoUg3ueo...",        // State hash (world state)
  "predecessor": "BLs8jGfH..."    // Previous block hash
}
```

**Key Fields Explained:**

- **`level`**: Block number in the chain (starts at 0 for genesis)
- **`hash`**: Cryptographic hash uniquely identifying this block
- **`timestamp`**: UTC time when the baker created the block
- **`protocol`**: Current Tezos protocol (PtSeouLouX = Quebec)
- **`fitness`**: Used for chain selection (higher = canonical chain)
- **`context`**: Hash of the entire blockchain state after this block
- **`predecessor`**: Links to previous block (forms the chain)

---

### 2. 📦 Operations (4 Validation Passes)

Operations are grouped into **4 validation passes**, each serving a different purpose:

#### **Pass 0: Endorsements (Consensus)**
- **Purpose**: Validators attest to the previous block
- **Types**: 
  - `attestation` - Basic consensus vote
  - `attestation_with_dal` - Attestation + Data Availability Layer proof
- **Example**: 13 endorsements per block (typical)
- **Gas**: 0 (free, part of consensus)

#### **Pass 1: Votes (Governance)**
- **Purpose**: Protocol amendment proposals and votes
- **Types**:
  - `proposals` - Propose protocol upgrades
  - `ballot` - Vote on protocol changes
- **Example**: 0 operations (only during governance periods)
- **Gas**: 0 (free)

#### **Pass 2: Anonymous Operations**
- **Purpose**: Operations that don't require a signature
- **Types**:
  - `seed_nonce_revelation` - Randomness for baker selection
  - `double_baking_evidence` - Proof of double-baking (slashing)
  - `double_attestation_evidence` - Proof of double-attestation
  - `activate_account` - Fundraiser account activation
- **Example**: 0 operations (occasional)
- **Gas**: Varies

#### **Pass 3: Manager Operations (User Transactions)**
- **Purpose**: User-initiated transactions and smart contract calls
- **Types**:
  - `transaction` - XTZ transfers
  - `origination` - Deploy new smart contracts
  - `delegation` - Delegate to a baker
  - `reveal` - Reveal public key
  - `smart_rollup_*` - Layer 2 rollup operations
  - `dal_publish_commitment` - Data Availability Layer
- **Example**: 3 operations in block 17035391
  - `smart_rollup_add_messages` - L2 data submission
  - `dal_publish_commitment` - DAL data commitment (x2)
- **Gas**: Varies (user pays fees)

**Example from Block 17035391:**
```
Total Operations: 16
  ├─ Pass 0 (Endorsements):   13 operations ✅
  ├─ Pass 1 (Votes):           0 operations
  ├─ Pass 2 (Anonymous):       0 operations
  └─ Pass 3 (Manager):         3 operations 💼
```

---

### 3. 📊 Block Metadata

Additional information about block execution:

- **`baker`**: Address that created this block (earns rewards)
- **`consumed_gas`**: Total gas used by all operations
- **`balance_updates`**: Changes to account balances (rewards, fees)
- **`level_info`**: Cycle, voting period information
- **`voting_period_info`**: Current governance state

**Example:**
```
Baker:          tz3RacukKe72q5mQSjiQ...
Consumed Gas:   5086 gas
Operations:     16
Block Size:     ~19KB (JSON)
```

---

### 4. 🔗 Blockchain Context

Connects this block to the chain:

- **`predecessor`**: Hash of previous block (creates the chain)
- **`context`**: State hash (Merkle root of all accounts/contracts)
- **`fitness`**: Chain weight (used for fork resolution)

**Example:**
```
Current Block:    #17035391
Previous Block:   BLs8jGfH... (block #17035390)
Block Time:       2025-12-19T13:24:46Z
Block Interval:   4s (time since previous block)
```

---

## Block Lifecycle

### 1. **Baker Selection**
- Protocol selects a baker based on stake and randomness
- Baker has priority to produce the block

### 2. **Operation Collection**
- Baker collects operations from mempool
- Groups operations into 4 validation passes
- Orders operations optimally

### 3. **Block Creation**
- Baker constructs block header
- Includes selected operations
- Computes new state (context hash)
- Signs the block with baker's key

### 4. **Block Propagation**
- Baker broadcasts block to network
- Peers validate and propagate
- Other validators endorse the block

### 5. **Endorsement**
- Validators attest to the block's validity
- Endorsements included in **next block** (Pass 0)
- Consensus reached (~⅔ of validators)

### 6. **Finality**
- Block becomes part of canonical chain
- After 2 confirmations: economically final
- After ~30 blocks: practically irreversible

---

## Block Timing

**Ghostnet (Testnet):**
- Block time: ~4 seconds
- Blocks per cycle: 16,384
- Cycle duration: ~18.2 hours

**Mainnet:**
- Block time: ~15 seconds  
- Blocks per cycle: 16,384
- Cycle duration: ~2.8 days

---

## Block Size & Limits

**Size Constraints:**
- Max operations per block: Protocol-dependent
- Max gas per block: 20,000,000 gas (Quebec protocol)
- Max operation size: 32 KB
- Block header size: ~200 bytes

**Typical Block (Ghostnet):**
- Size: 15-25 KB (JSON)
- Operations: 10-20
- Endorsements: 10-15
- Manager ops: 0-5

---

## Inspecting Blocks

### Via npm Scripts
```bash
# Current block
npm run block:inspect

# Specific block level
npm run block:inspect 17035391

# By hash
npm run block:inspect BLocqcR4bsD2RFLxwivqyAPupWJFAGDqfMW43rHf7xFNzxXZJqA
```

### Via RPC API
```bash
# Block header
curl http://127.0.0.1:8732/chains/main/blocks/head/header | jq

# All operations
curl http://127.0.0.1:8732/chains/main/blocks/head/operations | jq

# Block metadata
curl http://127.0.0.1:8732/chains/main/blocks/head/metadata | jq

# Specific operation pass
curl http://127.0.0.1:8732/chains/main/blocks/head/operations/3 | jq  # Manager ops

# Historical block
curl http://127.0.0.1:8732/chains/main/blocks/17035391 | jq
```

### Via octez-client
```bash
# Get block
docker exec tezos-node octez-client rpc get /chains/main/blocks/head

# Get specific level
docker exec tezos-node octez-client rpc get /chains/main/blocks/17035391
```

---

## Understanding Operation Types

### **Consensus Operations (Pass 0)**
| Operation | Purpose | Gas | Frequency |
|-----------|---------|-----|-----------|
| attestation | Endorse previous block | 0 | Every block |
| attestation_with_dal | Endorse + DAL proof | 0 | Every block |

### **Governance Operations (Pass 1)**
| Operation | Purpose | Gas | Frequency |
|-----------|---------|-----|-----------|
| proposals | Propose protocol upgrade | 0 | Proposal period |
| ballot | Vote on proposal | 0 | Voting periods |

### **Anonymous Operations (Pass 2)**
| Operation | Purpose | Gas | Frequency |
|-----------|---------|-----|-----------|
| seed_nonce_revelation | Reveal baker randomness | 0 | Every cycle |
| double_baking_evidence | Prove double-baking | 0 | Rare (slashing) |
| double_attestation_evidence | Prove double-attesting | 0 | Rare (slashing) |

### **Manager Operations (Pass 3)**
| Operation | Purpose | Gas | Frequency |
|-----------|---------|-----|-----------|
| transaction | Transfer XTZ | Variable | Common |
| origination | Deploy contract | High | Moderate |
| delegation | Delegate stake | Low | Moderate |
| reveal | Reveal public key | Low | Once per account |
| smart_rollup_* | Layer 2 operations | Variable | Growing |
| dal_publish_commitment | DAL data | Variable | Growing |

---

## Real Example: Block 17035391

```
Block Hash: BLocqcR4bsD2RFLxwivqyAPupWJFAGDqfMW43rHf7xFNzxXZJqA
Level:      #17035391
Time:       2025-12-19 13:24:46 UTC
Baker:      tz3RacukKe72q5mQSjiQ... (earned baking rewards)

Contents:
├─ Header
│  ├─ Protocol: PtSeouLouX (Quebec)
│  ├─ Context Hash: CoUg3ueoHrSDGpf...
│  └─ Predecessor: BLs8jGfHsqA7iqoiyj...
│
├─ Operations (16 total)
│  ├─ Pass 0: 13 attestations (consensus votes)
│  ├─ Pass 1: 0 votes
│  ├─ Pass 2: 0 anonymous
│  └─ Pass 3: 3 manager operations
│     ├─ smart_rollup_add_messages (L2 data)
│     ├─ dal_publish_commitment (DAL)
│     └─ dal_publish_commitment (DAL)
│
└─ Metadata
   ├─ Gas Used: 5,086 gas
   ├─ Block Size: ~19 KB
   └─ Block Interval: 4 seconds
```

---

## Key Concepts

### **Context Hash**
- Merkle root of entire blockchain state
- Changes with every block
- Enables state verification without full state

### **Fitness**
- Measure of chain weight
- Higher fitness = canonical chain
- Resolves forks automatically

### **Validation Passes**
- Operations grouped by type
- Validated in specific order
- Ensures consensus before user operations

### **Gas**
- Computational cost measure
- Prevents DoS attacks
- Users pay fees proportional to gas

---

## Additional Resources

```bash
# List all available RPC endpoints
curl http://127.0.0.1:8732/describe | jq

# Explore blocks
npm run block:inspect head
npm run block:inspect <level_or_hash>

# Monitor real-time blocks
npm run node:logs
```

**Official Documentation:**
- Tezos Block Structure: https://tezos.gitlab.io/shell/validation.html
- RPC API Reference: https://tezos.gitlab.io/shell/rpc.html
- Protocol Documentation: https://tezos.gitlab.io/active/protocol.html

---

**Last Updated**: 2024-12-19
