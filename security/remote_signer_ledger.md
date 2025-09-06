# Remote Signer with Ledger Hardware Wallet

## Overview

Remote signing separates key management from the Tezos node, providing enhanced security by isolating private keys on a dedicated hardware wallet (Ledger) accessed through a separate signer process.

## Architecture

```
[Tezos Node] <--RPC--> [Remote Signer] <--USB--> [Ledger Wallet]
```

- **Tezos Node**: Handles blockchain operations, no access to private keys
- **Remote Signer**: Manages key operations, communicates with Ledger
- **Ledger Wallet**: Hardware security module storing private keys

## Prerequisites

### Hardware Requirements
- Ledger Nano S or Ledger Nano X
- Dedicated computer for remote signer (recommended)
- USB connection between signer computer and Ledger

### Software Requirements
- Tezos Baking App installed on Ledger
- Octez client with Ledger support
- Linux system (Ubuntu/Debian recommended)

## Ledger Setup

### 1. Install Tezos Baking App
1. Connect Ledger to computer
2. Open Ledger Live application
3. Navigate to Manager tab
4. Search for "Tezos Baking"
5. Install the Tezos Baking application

### 2. Configure Ledger Settings
```bash
# Enable expert mode on Ledger device
# Settings > Security > Expert Mode > Enable

# Enable developer mode (if needed)
# Settings > Security > Developer Mode > Enable
```

### 3. Generate Baking Key
```bash
# Import Ledger key with specific derivation path
tezos-client import secret key baker-ledger "ledger://wallet-name/ed25519/0h/0h"

# Verify key import
tezos-client show address baker-ledger
```

## Remote Signer Configuration

### 1. Install Octez on Signer Machine
```bash
# Download and install Octez
wget https://github.com/serokell/tezos-packaging/releases/latest/download/tezos-client
chmod +x tezos-client
sudo mv tezos-client /usr/local/bin/

# Install Ledger support libraries
sudo apt update
sudo apt install -y libudev-dev libusb-1.0-0-dev
```

### 2. Configure Udev Rules
```bash
# Create udev rule for Ledger access
sudo tee /etc/udev/rules.d/20-ledger.rules << EOF
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0000", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0001", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0004", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"
EOF

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Add user to plugdev group
sudo usermod -a -G plugdev $USER
```

### 3. Launch Remote Signer
```bash
# Start HTTP remote signer
tezos-signer launch http signer \
  --address 0.0.0.0 \
  --port 6732 \
  --require-auth \
  --magic-bytes ledger

# Or start socket signer (more secure)
tezos-signer launch socket signer \
  --path /tmp/tezos-signer.sock \
  --require-auth \
  --magic-bytes ledger
```

### 4. Configure Authentication (Recommended)
```bash
# Generate authentication key
openssl rand -hex 32 > /etc/tezos/signer-auth.key
chmod 600 /etc/tezos/signer-auth.key

# Start signer with authentication
tezos-signer launch http signer \
  --address 127.0.0.1 \
  --port 6732 \
  --require-auth \
  --auth-file /etc/tezos/signer-auth.key
```

## Node Configuration

### 1. Configure Baker for Remote Signer
```bash
# Test remote signer connection
tezos-client --endpoint http://node-ip:8732 \
  import secret key baker-remote \
  http://signer-ip:6732/tz1YourBakerAddress

# Verify remote key
tezos-client show address baker-remote
```

### 2. Start Baker with Remote Signer
```bash
# Start baker using remote signer
tezos-baker-alpha run remote signer \
  http://signer-ip:6732 for baker-remote \
  --endpoint http://127.0.0.1:8732
```

### 3. Start Endorser with Remote Signer
```bash
# Start endorser using remote signer
tezos-endorser-alpha run remote signer \
  http://signer-ip:6732 for baker-remote \
  --endpoint http://127.0.0.1:8732
```

## Docker Configuration

### Remote Signer Compose File
```yaml
version: '3.8'

services:
  tezos-signer:
    build:
      context: .
      dockerfile: octez.Dockerfile
    container_name: tezos-signer
    restart: unless-stopped
    ports:
      - "127.0.0.1:6732:6732"
    volumes:
      - ./data:/var/lib/tezos
      - /dev:/dev:ro  # For Ledger access
    environment:
      - SIGNER_ADDRESS=0.0.0.0
      - SIGNER_PORT=6732
      - REQUIRE_AUTH=true
    devices:
      - /dev/bus/usb:/dev/bus/usb:rw
    privileged: true
    command: >
      tezos-signer launch http signer
      --address ${SIGNER_ADDRESS}
      --port ${SIGNER_PORT}
      --require-auth
```

### Node Configuration for Remote Signer
```yaml
# In docker-compose file for baker/endorser
environment:
  - REMOTE_SIGNER=true
  - REMOTE_SIGNER_URL=http://signer-host:6732
  - BAKER_ALIAS=baker-remote
```

## Security Considerations

### Network Security
```bash
# Restrict signer access to specific IPs only
sudo ufw allow from node-ip to any port 6732

# Use VPN for remote signer communication
# Configure WireGuard or similar VPN solution
```

### Monitoring Signer Activity
```bash
# Monitor signer logs
tail -f ~/.tezos-signer/logs/signer.log

# Check Ledger connection
tezos-signer list connected ledgers

# Monitor signing requests
tezos-signer get ledger tz1YourAddress authorized baking
```

### Backup and Recovery
```bash
# Backup Ledger seed phrase (store securely offline)
# The 24-word seed phrase is the ultimate backup

# Export public key hash for recovery
tezos-client show address baker-ledger --show-secret | grep "Public Key Hash"
```

## Operational Procedures

### Daily Operations
```bash
# Check Ledger connection
tezos-signer list connected ledgers

# Verify signing capability
tezos-client sign bytes 0x03 for baker-remote

# Monitor baking activity
tezos-client rpc get /chains/main/blocks/head/helpers/baking_rights
```

### Emergency Procedures

#### Signer Disconnect
```bash
# Check USB connection
lsusb | grep -i ledger

# Restart signer service
sudo systemctl restart tezos-signer

# Verify connection recovery
tezos-signer list connected ledgers
```

#### Hardware Failure
```bash
# Use backup Ledger device
# Import same seed phrase on new device
# Reconfigure signer to use new device

# Or switch to local keys temporarily
tezos-client import secret key baker-emergency unencrypted:edsk...
```

## High Availability Setup

### Redundant Signer Configuration
```bash
# Primary signer
tezos-signer launch http signer --address 0.0.0.0 --port 6732

# Backup signer (different machine/Ledger)
tezos-signer launch http signer --address 0.0.0.0 --port 6733

# Configure baker with failover
tezos-baker-alpha run remote signer \
  http://primary-signer:6732,http://backup-signer:6733 \
  for baker-remote
```

### Load Balancer Configuration
```nginx
# Nginx configuration for signer load balancing
upstream tezos_signers {
    server primary-signer:6732 max_fails=3 fail_timeout=30s;
    server backup-signer:6732 backup;
}

server {
    listen 6732;
    proxy_pass tezos_signers;
    proxy_connect_timeout 5s;
    proxy_timeout 30s;
}
```

## Monitoring and Alerting

### Signer Health Checks
```bash
#!/bin/bash
# Check signer availability
if curl -s http://signer-ip:6732/keys/baker-remote; then
    echo "Signer responsive"
else
    echo "ALERT: Signer not responding"
    # Send alert notification
fi

# Check Ledger connection
if tezos-signer list connected ledgers | grep -q "Found device"; then
    echo "Ledger connected"
else
    echo "ALERT: Ledger disconnected"
fi
```

### Prometheus Metrics
```bash
# Custom metrics endpoint for signer
cat > /var/lib/prometheus/node-exporter/tezos_signer.prom << EOF
# HELP tezos_signer_connected Ledger connection status
# TYPE tezos_signer_connected gauge
tezos_signer_connected{device="ledger"} 1

# HELP tezos_signer_signing_requests_total Total signing requests
# TYPE tezos_signer_signing_requests_total counter
tezos_signer_signing_requests_total 42
EOF
```

## Troubleshooting

### Common Issues

#### Ledger Not Detected
```bash
# Check USB connection
lsusb | grep -i ledger

# Check udev rules
ls -la /etc/udev/rules.d/20-ledger.rules

# Restart udev
sudo systemctl restart udev
```

#### Permission Denied
```bash
# Check user groups
groups $USER

# Add user to plugdev group
sudo usermod -a -G plugdev $USER

# Re-login or start new session
```

#### Signing Failures
```bash
# Check Ledger app is open
# Ensure Tezos Baking app is running on Ledger

# Check signer logs
tail -f ~/.tezos-signer/logs/signer.log

# Test manual signing
tezos-client sign bytes 0x03 for baker-remote
```

#### Network Connectivity
```bash
# Test signer endpoint
curl -v http://signer-ip:6732/keys

# Check firewall rules
sudo ufw status | grep 6732

# Test from baker node
telnet signer-ip 6732
```

---

**⚠️ Security Warning**: 
- Never expose the remote signer to the internet
- Use VPN or private networks for signer communication
- Keep Ledger firmware updated
- Store seed phrases securely offline
- Test recovery procedures regularly